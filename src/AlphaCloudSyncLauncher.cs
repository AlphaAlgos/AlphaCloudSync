using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("AlphaCloudSync")]
[assembly: AssemblyDescription("Smart Cloud Backup, Safe Restore & Persistent Explorer Drive for Windows")]
[assembly: AssemblyCompany("Alpha Algorithms Company")]
[assembly: AssemblyProduct("AlphaCloudSync")]
[assembly: AssemblyCopyright("Copyright (c) 2026 Alpha Algorithms Company (MIT License)")]
[assembly: AssemblyVersion("1.1.0.0")]
[assembly: AssemblyFileVersion("1.1.0.0")]

namespace AlphaCloudSync
{
    internal sealed class AlphaSplashForm : Form
    {
        [DllImport("gdi32.dll")]
        private static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);

        [DllImport("gdi32.dll")]
        private static extern bool DeleteObject(IntPtr hObject);

        private readonly string[] _stages;
        private readonly bool _isRtl;
        private readonly string _stageFile;
        private readonly Image _logoImg;
        private readonly System.Windows.Forms.Timer _tickTimer;

        private int _currentStage = 1;
        private bool _allDone = false;
        private bool _closingFade = false;
        private double _barProgress = 0.14;
        private int _pulsePhase = 0;
        private int _doneHoldTicks = 0;
        private volatile bool _forceClose = false;

        public AlphaSplashForm(string[] stages, bool isRtl, string stageFile, Image logoImg)
        {
            _stages = stages;
            _isRtl = isRtl;
            _stageFile = stageFile;
            _logoImg = logoImg;

            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.ShowInTaskbar = false;
            this.TopMost = true;
            this.Size = new Size(416, 294);
            this.BackColor = Color.FromArgb(8, 13, 23);
            this.DoubleBuffered = true;
            this.Opacity = 0.0;

            try
            {
                IntPtr rgn = CreateRoundRectRgn(0, 0, this.Width + 1, this.Height + 1, 20, 20);
                this.Region = Region.FromHrgn(rgn);
                DeleteObject(rgn);
            }
            catch { }

            _tickTimer = new System.Windows.Forms.Timer();
            _tickTimer.Interval = 40;
            _tickTimer.Tick += OnTick;
            _tickTimer.Start();
        }

        public void RequestImmediateClose()
        {
            _forceClose = true;
            try
            {
                if (this.IsHandleCreated && !this.IsDisposed)
                {
                    this.BeginInvoke((Action)(() => { try { this.Close(); } catch { } }));
                }
            }
            catch { }
        }

        private void OnTick(object sender, EventArgs e)
        {
            if (_forceClose)
            {
                _tickTimer.Stop();
                this.Close();
                return;
            }

            _pulsePhase = (_pulsePhase + 1) % 30;

            if (!_closingFade && this.Opacity < 1.0)
            {
                this.Opacity = Math.Min(1.0, this.Opacity + 0.18);
            }

            if (!_allDone && !string.IsNullOrEmpty(_stageFile) && File.Exists(_stageFile))
            {
                try
                {
                    string raw = File.ReadAllText(_stageFile, Encoding.UTF8).Trim();
                    if (string.Equals(raw, "DONE", StringComparison.OrdinalIgnoreCase))
                    {
                        _currentStage = _stages.Length;
                        _allDone = true;
                        _doneHoldTicks = 0;
                    }
                    else
                    {
                        int parsed;
                        if (int.TryParse(raw, out parsed))
                        {
                            if (parsed > _currentStage && parsed <= _stages.Length)
                            {
                                _currentStage = parsed;
                            }
                        }
                    }
                }
                catch { }
            }

            double targetBar = _allDone ? 1.0 : Math.Min(0.94, ((double)_currentStage - 0.15) / (double)_stages.Length);
            if (_barProgress < targetBar)
            {
                _barProgress = Math.Min(targetBar, _barProgress + 0.045);
            }

            if (_allDone)
            {
                _doneHoldTicks++;
                if (_doneHoldTicks >= 4)
                {
                    _closingFade = true;
                    this.Opacity = Math.Max(0.0, this.Opacity - 0.22);
                    if (this.Opacity <= 0.02)
                    {
                        _tickTimer.Stop();
                        this.Close();
                        return;
                    }
                }
            }

            this.Invalidate();
        }

        private static GraphicsPath CreateRoundedPath(Rectangle rect, int radius)
        {
            GraphicsPath path = new GraphicsPath();
            int d = radius * 2;
            path.AddArc(rect.X, rect.Y, d, d, 180, 90);
            path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90);
            path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90);
            path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;

            Rectangle fullRect = new Rectangle(0, 0, this.Width - 1, this.Height - 1);
            using (LinearGradientBrush bgBrush = new LinearGradientBrush(fullRect, Color.FromArgb(11, 18, 32), Color.FromArgb(7, 12, 22), 90f))
            {
                g.FillRectangle(bgBrush, fullRect);
            }

            // Subtle top cyan-to-emerald accent line
            using (LinearGradientBrush topBar = new LinearGradientBrush(new Rectangle(0, 0, this.Width, 3), Color.FromArgb(2, 132, 199), Color.FromArgb(16, 185, 129), 0f))
            {
                g.FillRectangle(topBar, 0, 0, this.Width, 3);
            }

            // Outer glowing border
            using (GraphicsPath borderPath = CreateRoundedPath(new Rectangle(0, 0, this.Width - 1, this.Height - 1), 10))
            using (Pen borderPen = new Pen(Color.FromArgb(36, 58, 92), 1.5f))
            {
                g.DrawPath(borderPen, borderPath);
            }

            // Header: Logo + Brand Name + Version Pill
            int headerY = 24;
            int logoSize = 42;
            int leftPad = 26;
            if (_logoImg != null)
            {
                g.DrawImage(_logoImg, new Rectangle(leftPad, headerY, logoSize, logoSize));
            }

            using (Font titleFont = new Font("Segoe UI", 14.5f, FontStyle.Bold))
            using (Brush titleBrush = new SolidBrush(Color.FromArgb(248, 250, 252)))
            {
                g.DrawString("AlphaCloudSync", titleFont, titleBrush, leftPad + logoSize + 13, headerY + 1);
            }

            using (Font subFont = new Font("Segoe UI", 8.5f, FontStyle.Regular))
            using (Brush subBrush = new SolidBrush(Color.FromArgb(100, 116, 139)))
            {
                g.DrawString("Backup. Sync. Restore.", subFont, subBrush, leftPad + logoSize + 14, headerY + 26);
            }

            Rectangle pillRect = new Rectangle(this.Width - 88, headerY + 8, 62, 22);
            using (GraphicsPath pillPath = CreateRoundedPath(pillRect, 10))
            using (SolidBrush pillBg = new SolidBrush(Color.FromArgb(16, 36, 62)))
            using (Pen pillBorder = new Pen(Color.FromArgb(30, 64, 108), 1f))
            using (Font pillFont = new Font("Segoe UI", 8f, FontStyle.Bold))
            using (SolidBrush pillText = new SolidBrush(Color.FromArgb(56, 189, 248)))
            {
                g.FillPath(pillBg, pillPath);
                g.DrawPath(pillBorder, pillPath);
                StringFormat sfC = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                g.DrawString("v1.1.0", pillFont, pillText, pillRect, sfC);
            }

            // Divider line
            using (Pen divPen = new Pen(Color.FromArgb(24, 38, 60), 1f))
            {
                g.DrawLine(divPen, leftPad, 80, this.Width - leftPad, 80);
            }

            // Stacked live startup stages (1.._currentStage)
            int startY = 96;
            int rowH = 31;
            int visibleCount = Math.Min(_currentStage, _stages.Length);
            StringFormat textFmt = new StringFormat { LineAlignment = StringAlignment.Center };
            if (_isRtl)
            {
                textFmt.FormatFlags = StringFormatFlags.DirectionRightToLeft;
                textFmt.Alignment = StringAlignment.Near;
            }
            else
            {
                textFmt.Alignment = StringAlignment.Near;
            }

            for (int i = 0; i < visibleCount; i++)
            {
                int y = startY + (i * rowH);
                bool isCompleted = _allDone || (i < visibleCount - 1);
                int iconX = _isRtl ? (this.Width - leftPad - 18) : leftPad;
                int iconY = y + 5;

                if (isCompleted)
                {
                    using (SolidBrush okBg = new SolidBrush(Color.FromArgb(15, 45, 32)))
                    using (Pen okRing = new Pen(Color.FromArgb(16, 185, 129), 1.4f))
                    using (Pen chkPen = new Pen(Color.FromArgb(74, 222, 128), 2.0f))
                    {
                        chkPen.StartCap = LineCap.Round;
                        chkPen.EndCap = LineCap.Round;
                        g.FillEllipse(okBg, iconX, iconY, 18, 18);
                        g.DrawEllipse(okRing, iconX, iconY, 18, 18);
                        g.DrawLines(chkPen, new PointF[]
                        {
                            new PointF(iconX + 5.0f, iconY + 9.2f),
                            new PointF(iconX + 8.0f, iconY + 12.2f),
                            new PointF(iconX + 13.2f, iconY + 6.2f)
                        });
                    }
                }
                else
                {
                    double wave = 0.45 + 0.55 * Math.Abs(Math.Sin(_pulsePhase * Math.PI / 15.0));
                    int alphaRing = (int)(70 + 140 * wave);
                    int alphaDot = (int)(130 + 125 * wave);
                    using (SolidBrush glowBg = new SolidBrush(Color.FromArgb(alphaRing / 3, 56, 189, 248)))
                    using (Pen glowRing = new Pen(Color.FromArgb(alphaRing, 56, 189, 248), 1.3f))
                    using (SolidBrush dotBrush = new SolidBrush(Color.FromArgb(alphaDot, 56, 189, 248)))
                    {
                        g.FillEllipse(glowBg, iconX, iconY, 18, 18);
                        g.DrawEllipse(glowRing, iconX, iconY, 18, 18);
                        g.FillEllipse(dotBrush, iconX + 5, iconY + 5, 8, 8);
                    }
                }

                Rectangle textRect = _isRtl
                    ? new Rectangle(leftPad, y, this.Width - (leftPad * 2) - 28, 28)
                    : new Rectangle(leftPad + 28, y, this.Width - (leftPad * 2) - 28, 28);

                using (Font stFont = new Font("Segoe UI", 9.8f, isCompleted ? FontStyle.Regular : FontStyle.Bold))
                using (SolidBrush stBrush = new SolidBrush(isCompleted ? Color.FromArgb(148, 163, 184) : Color.FromArgb(241, 245, 249)))
                {
                    g.DrawString(_stages[i], stFont, stBrush, textRect, textFmt);
                }
            }

            // Bottom sleek animated progress bar
            Rectangle trackRect = new Rectangle(leftPad, this.Height - 24, this.Width - (leftPad * 2), 6);
            using (GraphicsPath trackPath = CreateRoundedPath(trackRect, 3))
            using (SolidBrush trackBrush = new SolidBrush(Color.FromArgb(17, 30, 51)))
            {
                g.FillPath(trackBrush, trackPath);
            }

            int fillW = Math.Max(12, (int)(trackRect.Width * Math.Max(0.05, Math.Min(1.0, _barProgress))));
            Rectangle fillRect = _isRtl
                ? new Rectangle(trackRect.Right - fillW, trackRect.Y, fillW, trackRect.Height)
                : new Rectangle(trackRect.X, trackRect.Y, fillW, trackRect.Height);
            using (GraphicsPath fillPath = CreateRoundedPath(fillRect, 3))
            using (LinearGradientBrush fillBrush = new LinearGradientBrush(trackRect, Color.FromArgb(56, 189, 248), Color.FromArgb(34, 197, 94), 0f))
            {
                g.FillPath(fillBrush, fillPath);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                try { if (_tickTimer != null) _tickTimer.Dispose(); } catch { }
                try { if (_logoImg != null) _logoImg.Dispose(); } catch { }
            }
            base.Dispose(disposing);
        }
    }

    internal static class Program
    {
        private const string AppVersion = "1.1.0";
        private const string AppUserModelId = "AlphaAlgorithms.AlphaCloudSync";
        private const string RestoreSignalName = "Local\\AlphaCloudSync_RestoreSignal";

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        private static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);

        [DllImport("kernel32.dll")]
        private static extern bool AttachConsole(int dwProcessId);

        [DllImport("kernel32.dll")]
        private static extern bool FreeConsole();

        [DllImport("user32.dll")]
        private static extern bool AllowSetForegroundWindow(int dwProcessId);

        private static string EscapeJsonString(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            StringBuilder sb = new StringBuilder(input.Length + 8);
            foreach (char c in input)
            {
                switch (c)
                {
                    case '\\': sb.Append("\\\\"); break;
                    case '"':  sb.Append("\\\""); break;
                    case '\r': sb.Append("\\r"); break;
                    case '\n': sb.Append("\\n"); break;
                    case '\t': sb.Append("\\t"); break;
                    case '\b': sb.Append("\\b"); break;
                    case '\f': sb.Append("\\f"); break;
                    default:
                        if (c < 0x20) sb.AppendFormat("\\u{0:x4}", (int)c);
                        else sb.Append(c);
                        break;
                }
            }
            return sb.ToString();
        }

        private static string DecodeJsonStringValue(string raw)
        {
            if (string.IsNullOrEmpty(raw)) return "";
            return Regex.Replace(raw, @"\\u([0-9A-Fa-f]{4})", m => ((char)Convert.ToInt32(m.Groups[1].Value, 16)).ToString())
                        .Replace("\\\"", "\"")
                        .Replace("\\\\", "\\");
        }

        private static string ReadUserLanguageCode()
        {
            try
            {
                string settingsFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "AlphaCloudSync", "settings.json");
                if (File.Exists(settingsFile))
                {
                    string txt = File.ReadAllText(settingsFile, Encoding.UTF8);
                    Match m = Regex.Match(txt, "\"Language\"\\s*:\\s*\"([a-zA-Z]{2})\"");
                    if (m.Success) return m.Groups[1].Value.ToLowerInvariant();
                }
            }
            catch { }
            return "en";
        }

        private static void LoadSplashLocale(out string[] stages, out bool isRtl)
        {
            stages = new string[]
            {
                "Launching AlphaCloudSync...",
                "Preparing startup & interface...",
                "Loading accounts & folders...",
                "Preparing virtual drives...",
                "Opening studio workspace..."
            };
            isRtl = false;
            try
            {
                string lang = ReadUserLanguageCode();
                Assembly asm = Assembly.GetExecutingAssembly();
                string resName = "locales__" + lang + ".json";
                Stream st = asm.GetManifestResourceStream(resName);
                if (st == null) st = asm.GetManifestResourceStream("locales__en.json");
                if (st != null)
                {
                    using (st)
                    using (StreamReader sr = new StreamReader(st, Encoding.UTF8))
                    {
                        string json = sr.ReadToEnd();
                        Match mRtl = Regex.Match(json, "\"rtl\"\\s*:\\s*(true|false)", RegexOptions.IgnoreCase);
                        if (mRtl.Success) isRtl = string.Equals(mRtl.Groups[1].Value, "true", StringComparison.OrdinalIgnoreCase);
                        for (int i = 0; i < 5; i++)
                        {
                            string key = "splashStage" + (i + 1).ToString();
                            Match mVal = Regex.Match(json, "\"" + key + "\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");
                            if (mVal.Success)
                            {
                                string val = DecodeJsonStringValue(mVal.Groups[1].Value);
                                if (!string.IsNullOrEmpty(val)) stages[i] = val;
                            }
                        }
                    }
                }
            }
            catch { }
        }

        private static Image LoadEmbeddedLogo()
        {
            try
            {
                Assembly asm = Assembly.GetExecutingAssembly();
                using (Stream st = asm.GetManifestResourceStream("assets__AlphaCloudSync-icon.png"))
                {
                    if (st != null)
                    {
                        using (Image tmp = Image.FromStream(st))
                        {
                            return new Bitmap(tmp);
                        }
                    }
                }
            }
            catch { }
            return null;
        }

        [STAThread]
        private static int Main(string[] args)
        {
            try { SetCurrentProcessExplicitAppUserModelID(AppUserModelId); } catch { }

            bool isHeadlessCli = false;
            bool isMinimized = false;
            string contextAction = "";
            string contextTargetPath = "";
            for (int i = 0; i < args.Length; i++)
            {
                string a = args[i] ?? "";
                if (string.Equals(a, "--minimized", StringComparison.OrdinalIgnoreCase) || string.Equals(a, "-Minimized", StringComparison.OrdinalIgnoreCase))
                {
                    isMinimized = true;
                }
                else if (string.Equals(a, "-Action", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
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
                else if (a.StartsWith("-TargetPath:", StringComparison.OrdinalIgnoreCase))
                {
                    contextTargetPath = a.Substring(12);
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
                            string ipcQueueDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AlphaCloudSync", "ipc-queue");
                            Directory.CreateDirectory(ipcQueueDir);
                            string qStem = DateTime.UtcNow.Ticks.ToString() + "_" + Process.GetCurrentProcess().Id.ToString();
                            string tmpFile = Path.Combine(ipcQueueDir, qStem + ".tmp");
                            string finFile = Path.Combine(ipcQueueDir, qStem + ".json");
                            string payload = "{\"Action\":\"" + EscapeJsonString(contextAction) + "\",\"Path\":\"" + EscapeJsonString(contextTargetPath ?? "") + "\"}";
                            File.WriteAllText(tmpFile, payload, new UTF8Encoding(false));
                            File.Move(tmpFile, finFile);
                        }
                        try { AllowSetForegroundWindow(-1); } catch { }
                        using (EventWaitHandle restoreEvt = EventWaitHandle.OpenExisting(RestoreSignalName))
                        {
                            restoreEvt.Set();
                        }
                    }
                    catch { }
                    finally
                    {
                        try { guiMutex.Dispose(); } catch { }
                    }
                    return 0;
                }
            }

            bool attachedConsole = false;
            AlphaSplashForm splashForm = null;
            string splashStageFile = "";
            try
            {
                string localAppBase = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AlphaCloudSync");
                Directory.CreateDirectory(localAppBase);

                // Instant (~30ms) Obsidian Dark Splash Card for interactive GUI launch!
                if (!isHeadlessCli && !isMinimized)
                {
                    try
                    {
                        splashStageFile = Path.Combine(localAppBase, "splash-stage-" + Process.GetCurrentProcess().Id.ToString() + ".txt");
                        File.WriteAllText(splashStageFile, "1", new UTF8Encoding(false));
                        string[] splashStages;
                        bool splashRtl;
                        LoadSplashLocale(out splashStages, out splashRtl);
                        Image splashLogo = LoadEmbeddedLogo();
                        ManualResetEventSlim splashReady = new ManualResetEventSlim(false);
                        Thread splashThread = new Thread(() =>
                        {
                            try
                            {
                                Application.EnableVisualStyles();
                                splashForm = new AlphaSplashForm(splashStages, splashRtl, splashStageFile, splashLogo);
                                splashReady.Set();
                                Application.Run(splashForm);
                            }
                            catch
                            {
                                splashReady.Set();
                            }
                        });
                        splashThread.SetApartmentState(ApartmentState.STA);
                        splashThread.IsBackground = true;
                        splashThread.Start();
                        splashReady.Wait(500);
                    }
                    catch { }
                }

                string runtimeRoot = Path.Combine(localAppBase, "runtime", "v" + AppVersion);
                ExtractEmbeddedRuntime(runtimeRoot);

                if (!string.IsNullOrEmpty(splashStageFile))
                {
                    try { File.WriteAllText(splashStageFile, "2", new UTF8Encoding(false)); } catch { }
                }

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
                if (!string.IsNullOrEmpty(splashStageFile))
                {
                    psi.EnvironmentVariables["ALPHACLOUDSYNC_SPLASH_FILE"] = splashStageFile;
                }

                if (isHeadlessCli)
                {
                    try { if (!Console.IsOutputRedirected) attachedConsole = AttachConsole(-1); } catch { }
                    try { Console.OutputEncoding = new UTF8Encoding(false); } catch { }
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    psi.StandardOutputEncoding = Encoding.UTF8;
                    psi.StandardErrorEncoding = Encoding.UTF8;
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
                        try { AllowSetForegroundWindow(p.Id); } catch { }
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
                if (splashForm != null)
                {
                    try { splashForm.RequestImmediateClose(); } catch { }
                }
                if (!string.IsNullOrEmpty(splashStageFile))
                {
                    try { if (File.Exists(splashStageFile)) File.Delete(splashStageFile); } catch { }
                }
                if (attachedConsole)
                {
                    try { FreeConsole(); } catch { }
                }
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
