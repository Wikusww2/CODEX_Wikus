import type { ExecInput } from "./sandbox/interface.js";
import type { AppConfig } from "../config.js";
import type {
  ApprovalPolicy,
  ApplyPatchCommand,
  SafetyAssessment,
} from "../../approvals.js";
import type { CommandConfirmation } from "./agent-loop.js";

import { canAutoApprove } from "../../approvals.js";
import { ReviewDecision } from "./review.js";
import { startTerminalCommand } from "./terminal-exec.js";

type HandleExecCommandResult = {
  outputText: string;
  metadata: Record<string, unknown>;
  additionalItems?: Array<any>;
};

export async function handleExecCommand(
  args: ExecInput,
  config: AppConfig,
  policy: ApprovalPolicy,
  additionalWritableRoots: ReadonlyArray<string>,
  getCommandConfirmation: (
    command: Array<string>,
    applyPatch: ApplyPatchCommand | undefined,
  ) => Promise<CommandConfirmation>,
  abortSignal?: AbortSignal,
): Promise<HandleExecCommandResult> {
  const command = args.cmd;
  const workdir = args.workdir;

  // Assess command safety
  const assessment: SafetyAssessment = canAutoApprove(
    command,
    workdir,
    policy,
    additionalWritableRoots,
    process.env,
    config.safeCommands,
  );

  let userDecision: ReviewDecision = ReviewDecision.NO_CONTINUE;
  let explanation: string | undefined;

  if (assessment.type === "auto-approve") {
    userDecision = ReviewDecision.YES;
  } else if (assessment.type === "ask-user") {
    const confirmation = await getCommandConfirmation(command, undefined);
    userDecision = confirmation.review;
    explanation = confirmation.explanation;
  } else if (assessment.type === "reject") {
    return {
      outputText: `Command rejected: ${assessment.reason}`,
      metadata: { exit_code: -1, error: assessment.reason },
    };
  }

  if (
    userDecision === ReviewDecision.YES ||
    userDecision === ReviewDecision.YES_ONCE
  ) {
    return new Promise<HandleExecCommandResult>((resolve) => {
      let outputText = "";
      const session = startTerminalCommand(command, {
        sandbox: assessment.type === "auto-approve" && assessment.runInSandbox ? 
          { type: "default", writable_roots: additionalWritableRoots } : 
          undefined,
        config,
        workdir: workdir,
        env: process.env,
        abortSignal: abortSignal,
        explanation: explanation,
      });
      session.onData((data: string) => {
        outputText += data;
      });
      session.onExit((exitCode: number) => {
        resolve({
          outputText,
          metadata: {
            exit_code: exitCode,
          },
        });
      });
      session.onError((error: Error) => {
        resolve({
          outputText: error.message,
          metadata: {
            exit_code: -1, // Indicate error
            error: error.message,
          },
        });
      });
    });
  } else {
    // User denied or chose to explain (which implies denial for now)
    return {
      outputText: `Command execution denied by user. Reason: ${userDecision}`,
      metadata: { exit_code: -1, error: "Command execution denied by user." },
    };
  }
}

