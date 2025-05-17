import * as pty from 'node-pty';
import type { SandboxType } from './sandbox/interface.js';
import { getDefaultShell } from "./get-default-shell";

export interface TerminalSession {
  onData: (cb: (data: string) => void) => void;
  onExit: (cb: (code: number) => void) => void;
  sendInput: (input: string) => void;
  kill: () => void;
}

interface TerminalExecOptions {
  sandbox: SandboxType;
  shell?: string;
  workdir?: string;
  cols?: number;
  rows?: number;
  name?: string;
  env?: NodeJS.ProcessEnv;
  resourceLimits?: {
    memoryMb?: number;
    cpuSeconds?: number;
    timeoutMs?: number;
  };
}

/**
 * Starts a sandboxed terminal session to execute a command.
 * Uses PTY for true terminal emulation and real-time UX.
 */
export function startTerminalCommand(
  cmd: string[], // This is what the user typed, e.g., ['dir'] or ['cd', '/some/path']
  options: TerminalExecOptions,
): TerminalSession {
  const effectiveShell = options.shell || getDefaultShell();
  const workdir = options.workdir || process.cwd();
  const commandToRun = cmd.join(' '); // The complete command string, e.g., "cd /some/path" or "dir"

  let spawnArgs: string[];

  if (process.platform === 'win32') {
    if (effectiveShell.toLowerCase().includes('powershell')) {
      // For PowerShell, wrap the command in a script block for robustness
      spawnArgs = ['-NoProfile', '-NonInteractive', '-Command', `& {${commandToRun}}`];
    } else if (effectiveShell.toLowerCase().includes('cmd.exe')) {
      spawnArgs = ['/c', commandToRun];
    } else {
      // For other shells on Windows (e.g., bash.exe from Git Bash, sh.exe)
      // Assume they use -c like their Unix counterparts.
      console.warn(
        `[terminal-exec] Windows: configured shell '${effectiveShell}' is not PowerShell or cmd.exe. Attempting to use -c flag for command: ${commandToRun}`
      );
      spawnArgs = ['-c', commandToRun];
    }
  } else {
    // For Unix-like platforms (Linux, macOS)
    spawnArgs = ['-c', commandToRun];
  }

  const ptyProcess = pty.spawn(effectiveShell, spawnArgs, {
    name: options.name || 'xterm-color',
    cols: options.cols || 80,
    rows: options.rows || 30,
    cwd: workdir,
    env: { ...(process.env as NodeJS.ProcessEnv), ...(options.env as NodeJS.ProcessEnv) }, // Ensure env is NodeJS.ProcessEnv
  });

  return {
    onData: (cb) => ptyProcess.onData(cb),
    onExit: (cb) => ptyProcess.onExit(({ exitCode }) => cb(exitCode)),
    sendInput: (input) => ptyProcess.write(input),
    kill: () => ptyProcess.kill(),
  };
}

// TODO: Add Docker/nsjail/seatbelt integration for sandboxing
// TODO: Add resource limit enforcement
// TODO: Add approval/policy hooks before execution
// TODO: Add streaming integration to UI layer
