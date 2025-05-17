import type { ExecInput } from './sandbox/interface.js';
import type { AppConfig } from '../config.js';
import type { ApprovalPolicy, ApplyPatchCommand } from '../../approvals.js';
import type { CommandConfirmation } from './agent-loop.js';
import { startTerminalCommand } from './terminal-exec.js';

type HandleExecCommandResult = {
  outputText: string;
  metadata: Record<string, unknown>;
  additionalItems?: Array<any>;
};

export async function handleExecCommand(
  args: ExecInput,
  config: AppConfig,
  _policy: ApprovalPolicy,
  _additionalWritableRoots: ReadonlyArray<string>,
  _getCommandConfirmation: (
    command: Array<string>,
    applyPatch: ApplyPatchCommand | undefined,
  ) => Promise<CommandConfirmation>,
  _abortSignal?: AbortSignal,
): Promise<HandleExecCommandResult> {
  return new Promise<HandleExecCommandResult>((resolve) => {
    let outputText = '';
    const session = startTerminalCommand(args.cmd, {
      sandbox: undefined as any,
      config,
      workdir: args.workdir,
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
  });
}

