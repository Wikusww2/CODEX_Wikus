import * as os from 'os';

/**
 * Gets the default shell for the current operating system.
 *
 * @returns The default shell executable (e.g., 'powershell.exe', 'bash').
 */
export function getDefaultShell(): string {
  if (process.platform === 'win32') {
    // Prioritize PowerShell Core (pwsh) if available, otherwise Windows PowerShell
    // This could be expanded with a check if pwsh.exe is in PATH
    return 'powershell.exe'; // Could also check for 'pwsh.exe'
  } else if (process.env['SHELL']) {
    return process.env['SHELL'];
  } else {
    // Common defaults for Unix-like systems if SHELL env var is not set
    if (os.platform() === 'darwin') {
      return '/bin/zsh'; // Modern macOS default
    }
    return '/bin/sh'; // Fallback for other Unix-like systems
  }
}
