using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

[assembly: AssemblyTitle("AlphaCloudSync")]
[assembly: AssemblyDescription("Smart Cloud Backup, Safe Restore & Persistent Explorer Drive for Windows")]
[assembly: AssemblyCompany("Alpha Algorithms Company")]
[assembly: AssemblyProduct("AlphaCloudSync")]
[assembly: AssemblyCopyright("Copyright (c) 2026 Alpha Algorithms Company (MIT License)")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace AlphaCloudSync
{
    internal static class Program
    {
        private const string AppVersion = "1.0.0";
        private const string AppUserModelId = "AlphaAlgorithms.AlphaCloudSync";
        private const string RestoreSignalName = "Local\\AlphaCloudSync_RestoreSignal";

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        private static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);

        [STAThread]
        private static int Main(string[] args)
        {
            try { SetCurrentProcessExplicitAppUserModelID(AppUserModelId); } catch { }

            bool isHeadlessCli = false;
            string contextAction = "";
            string contextTargetPath = "";
            for (int i = 0; i < args.Length; i++)
            {
                string a = args[i] ?? "";
                if (string.Equals(a, "-Action", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
                {
                    string val = args[i + 1] ?? "";
                    if (val.StartsWith("Context", StringComparison.OrdinalIgnoreCase))
                    {
                        contextAction = val;
                    }
                    else if (!string.Equals(val, "GUI", StringComparison.OrdinalIgnoreCase))
                    {
                        isHeadlessCli = true;
                    }
                }
                else if (a.StartsWith("-Action:", StringComparison.OrdinalIgnoreCase))
                {
                    string val = a.Substring(8).Trim();
                    if (val.StartsWith("Context", StringComparison.OrdinalIgnoreCase))
                    {
                        contextAction = val;
                    }
                    else if (!string.Equals(val, "GUI", StringComparison.OrdinalIgnoreCase))
                    {
                        isHeadlessCli = true;
                    }
                }
                else if (string.Equals(a, "-TargetPath", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
                {
                    contextTargetPath = args[i + 1] ?? "";
                }
            }

            Mutex guiMutex = null;
            if (!isHeadlessCli)
            {
                bool createdNew;
                guiMutex = new Mutex(true, "Local\\AlphaCloudSync_SingleInstance_GUI", out createdNew);
                if (!createdNew)
                {
                    try
                    {
                        if (!string.IsNullOrEmpty(contextAction))
                        {
                            string ipcDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AlphaCloudSync");
                            Directory.CreateDirectory(ipcDir);
                            string ipcFile = Path.Combine(ipcDir, "ipc-command.json");
                            string safePath = (contextTargetPath ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"");
                            string safeAct  = contextAction.Replace("\\", "\\\\").Replace("\"", "\\\"");
                            File.WriteAllText(ipcFile, "{\"Action\":\"" + safeAct + "\",\"Path\":\"" + safePath + "\"}", new UTF8Encoding(false));
                        }
                        using (EventWaitHandle restoreEvt = EventWaitHandle.OpenExisting(RestoreSignalName))
                        {
                            restoreEvt.Set();
                        }
                    }
                    catch { }
                    return 0;
                }
            }

            try
            {
                string runtimeRoot = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "AlphaCloudSync",
                    "runtime",
                    "v" + AppVersion
                );

                ExtractEmbeddedRuntime(runtimeRoot);

                string mainScript = Path.Combine(runtimeRoot, "src", "AlphaCloudSync.ps1");
                if (!File.Exists(mainScript))
                {
                    return 2;
                }

                string psArgs = BuildPowerShellArguments(mainScript, args);
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    "WindowsPowerShell", "v1.0", "powershell.exe"
                );
                if (!File.Exists(psi.FileName))
                {
                    psi.FileName = "powershell.exe";
                }
                psi.Arguments = psArgs;
                psi.WorkingDirectory = runtimeRoot;
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;
                psi.EnvironmentVariables["ALPHACLOUDSYNC_EXE_PATH"] = Assembly.GetExecutingAssembly().Location;
                psi.EnvironmentVariables["ALPHACLOUDSYNC_RUNTIME_ROOT"] = runtimeRoot;

                if (isHeadlessCli)
                {
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    using (Process p = Process.Start(psi))
                    {
                        var outTask = p.StandardOutput.ReadToEndAsync();
                        var errTask = p.StandardError.ReadToEndAsync();
                        p.WaitForExit();
                        string stdout = outTask.GetAwaiter().GetResult();
                        string stderr = errTask.GetAwaiter().GetResult();
                        if (!string.IsNullOrEmpty(stdout)) Console.Write(stdout);
                        if (!string.IsNullOrEmpty(stderr)) Console.Error.Write(stderr);
                        return p.ExitCode;
                    }
                }
                else
                {
                    using (Process p = Process.Start(psi))
                    {
                        p.WaitForExit();
                        return p.ExitCode;
                    }
                }
            }
            catch (Exception ex)
            {
                try
                {
                    string logPath = Path.Combine(Path.GetTempPath(), "alphacloudsync_launcher_error.log");
                    File.WriteAllText(logPath, DateTime.Now.ToString("o") + Environment.NewLine + ex.ToString(), Encoding.UTF8);
                }
                catch { }
                return 1;
            }
            finally
            {
                if (guiMutex != null)
                {
                    try { guiMutex.ReleaseMutex(); } catch { }
                    guiMutex.Dispose();
                }
            }
        }

        private static void ExtractEmbeddedRuntime(string runtimeRoot)
        {
            using (Mutex extractMutex = new Mutex(false, "Local\\AlphaCloudSync_ExtractLock"))
            {
                bool acquired = false;
                try
                {
                    try { acquired = extractMutex.WaitOne(15000); }
                    catch (AbandonedMutexException) { acquired = true; }
                    if (!acquired)
                    {
                        throw new TimeoutException("Timed out waiting for the AlphaCloudSync runtime extraction lock.");
                    }

                    // Clean legacy old icon filename if present from earlier builds
                    try
                    {
                        string legacyIcon = Path.Combine(runtimeRoot, "assets", "AlphaCloudSync.ico");
                        if (File.Exists(legacyIcon)) File.Delete(legacyIcon);
                    }
                    catch { }

                    Assembly asm = Assembly.GetExecutingAssembly();
                    string[] names = asm.GetManifestResourceNames();

                    foreach (string resName in names)
                    {
                        // Resource names follow convention: relpath using "__" as directory separator (e.g., "src__AlphaCloudSync.ps1")
                        string relPath = resName.Replace("__", Path.DirectorySeparatorChar.ToString());
                        string destPath = Path.Combine(runtimeRoot, relPath);
                        string destDir = Path.GetDirectoryName(destPath);
                        if (!Directory.Exists(destDir))
                        {
                            Directory.CreateDirectory(destDir);
                        }

                        using (Stream resStream = asm.GetManifestResourceStream(resName))
                        {
                            if (resStream == null) continue;
                            bool shouldWrite = !File.Exists(destPath) || (new FileInfo(destPath).Length != resStream.Length);
                            if (!shouldWrite)
                            {
                                if (File.GetLastWriteTimeUtc(asm.Location) > File.GetLastWriteTimeUtc(destPath))
                                {
                                    shouldWrite = true;
                                }
                            }
                            if (shouldWrite)
                            {
                                string tmpPath = destPath + "." + Process.GetCurrentProcess().Id + ".tmp";
                                try
                                {
                                    using (FileStream fs = new FileStream(tmpPath, FileMode.Create, FileAccess.Write, FileShare.None))
                                    {
                                        resStream.CopyTo(fs);
                                    }
                                    if (File.Exists(destPath))
                                    {
                                        File.Copy(tmpPath, destPath, true);
                                        File.Delete(tmpPath);
                                    }
                                    else
                                    {
                                        File.Move(tmpPath, destPath);
                                    }
                                }
                                finally
                                {
                                    try { if (File.Exists(tmpPath)) File.Delete(tmpPath); } catch { }
                                }
                            }
                        }
                    }
                }
                finally
                {
                    if (acquired)
                    {
                        try { extractMutex.ReleaseMutex(); } catch { }
                    }
                }
            }
        }

        private static string BuildPowerShellArguments(string scriptPath, string[] userArgs)
        {
            List<string> parts = new List<string>();
            parts.Add("-NoProfile");
            parts.Add("-ExecutionPolicy Bypass");
            parts.Add("-WindowStyle Hidden");
            parts.Add("-File " + QuoteArg(scriptPath));

            foreach (string raw in userArgs)
            {
                if (string.Equals(raw, "--minimized", StringComparison.OrdinalIgnoreCase))
                {
                    parts.Add("-Minimized");
                }
                else
                {
                    parts.Add(QuoteArg(raw));
                }
            }
            return string.Join(" ", parts.ToArray());
        }

        private static string QuoteArg(string value)
        {
            if (string.IsNullOrEmpty(value)) return "\"\"";
            if (value.StartsWith("-") && value.IndexOfAny(new[] { ' ', '\t', '\r', '\n', '"' }) < 0) return value;
            StringBuilder sb = new StringBuilder();
            sb.Append('"');
            int backslashes = 0;
            for (int i = 0; i < value.Length; i++)
            {
                char c = value[i];
                if (c == '\\')
                {
                    backslashes++;
                }
                else if (c == '"')
                {
                    sb.Append('\\', backslashes * 2 + 1);
                    sb.Append('"');
                    backslashes = 0;
                }
                else
                {
                    if (backslashes > 0)
                    {
                        sb.Append('\\', backslashes);
                        backslashes = 0;
                    }
                    sb.Append(c);
                }
            }
            if (backslashes > 0) sb.Append('\\', backslashes * 2);
            sb.Append('"');
            return sb.ToString();
        }
    }
}
