# ==============================================================================
# AlphaCloudSync Module: UI.Interop (WPF Assemblies, WinShellHelper, DarkTrayRenderer, FolderWatchHub, DPI)
# ==============================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Native Windows 11 Taskbar Identity & Icon Binding (Replaces PowerShell icon with AlphaCloudSync!)
try {
    if (-not ("AlphaWinShellHelper" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class AlphaWinShellHelper {
    private const uint IMAGE_ICON = 1;
    private const uint LR_LOADFROMFILE = 0x0010;
    private const uint WM_SETICON = 0x0080;

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadImage(IntPtr hInst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    private struct PROPERTYKEY {
        public Guid fmtid;
        public uint pid;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROPVARIANT {
        public ushort vt;
        public ushort wReserved1;
        public ushort wReserved2;
        public ushort wReserved3;
        public IntPtr ptr;
        public IntPtr ptr2;
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore {
        int GetCount(out uint cProps);
        int GetAt(uint iProp, out PROPERTYKEY pkey);
        int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        int SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        int Commit();
    }

    [DllImport("shell32.dll")]
    private static extern int SHGetPropertyStoreForWindow(IntPtr hwnd, ref Guid iid, [Out, MarshalAs(UnmanagedType.Interface)] out IPropertyStore propertyStore);

    [DllImport("ole32.dll")]
    private static extern int PropVariantClear(ref PROPVARIANT pvar);

    private static void SetStrProp(IPropertyStore store, Guid fmtid, uint pid, string val) {
        if (string.IsNullOrEmpty(val)) return;
        PROPERTYKEY key = new PROPERTYKEY { fmtid = fmtid, pid = pid };
        PROPVARIANT pv = new PROPVARIANT();
        pv.vt = 31; // VT_LPWSTR
        pv.ptr = Marshal.StringToCoTaskMemUni(val);
        try { store.SetValue(ref key, ref pv); }
        finally { PropVariantClear(ref pv); }
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern void SHChangeNotify(int wEventId, uint uFlags, string dwItem1, string dwItem2);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("user32.dll")]
    private static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr SetActiveWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    public static void NotifyPathChanged(string path) {
        try {
            if (!string.IsNullOrEmpty(path)) {
                SHChangeNotify(0x00001000, 0x0005, path, null);
                SHChangeNotify(0x00002000, 0x0005, path, null);
            }
        } catch { }
    }

    public static void NotifyDriveIconChanged() {
        try { SHChangeNotify(0x08000000, 0x0000, null, null); } catch { }
    }

    public static void NotifyDriveAdded(string driveRoot) {
        try {
            if (!string.IsNullOrEmpty(driveRoot)) {
                SHChangeNotify(0x00000100, 0x0005, driveRoot, null);
                SHChangeNotify(0x00001000, 0x0005, driveRoot, null);
            }
            SHChangeNotify(0x08000000, 0x0000, null, null);
        } catch { }
    }

    public static void NotifyDriveRemoved(string driveRoot) {
        try {
            if (!string.IsNullOrEmpty(driveRoot)) {
                SHChangeNotify(0x00000080, 0x0005, driveRoot, null);
            }
            SHChangeNotify(0x08000000, 0x0000, null, null);
        } catch { }
    }

    public static void ForceForeground(IntPtr hwnd) {
        try {
            if (hwnd == IntPtr.Zero) return;
            IntPtr fg = GetForegroundWindow();
            uint curTid = GetCurrentThreadId();
            uint fgPid = 0;
            uint fgTid = (fg != IntPtr.Zero) ? GetWindowThreadProcessId(fg, out fgPid) : 0;
            bool attached = false;
            try {
                if (fgTid != 0 && fgTid != curTid) {
                    attached = AttachThreadInput(curTid, fgTid, true);
                }
                ShowWindow(hwnd, IsIconic(hwnd) ? 9 : 5);
                BringWindowToTop(hwnd);
                SetForegroundWindow(hwnd);
                SetActiveWindow(hwnd);
            } finally {
                if (attached) {
                    try { AttachThreadInput(curTid, fgTid, false); } catch { }
                }
            }
        } catch { }
    }

    public static void ApplyTaskbarIdentity(IntPtr hwnd, string appId, string icoPath, string exePath, string displayName) {
        try {
            if (hwnd == IntPtr.Zero) return;
            if (!string.IsNullOrEmpty(icoPath) && System.IO.File.Exists(icoPath)) {
                IntPtr hBig = LoadImage(IntPtr.Zero, icoPath, IMAGE_ICON, 48, 48, LR_LOADFROMFILE);
                IntPtr hSmall = LoadImage(IntPtr.Zero, icoPath, IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
                if (hBig != IntPtr.Zero) SendMessage(hwnd, WM_SETICON, (IntPtr)1, hBig);
                if (hSmall != IntPtr.Zero) SendMessage(hwnd, WM_SETICON, IntPtr.Zero, hSmall);
            }
            Guid iid = new Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99");
            IPropertyStore store;
            if (SHGetPropertyStoreForWindow(hwnd, ref iid, out store) == 0 && store != null) {
                Guid aumidFmt = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3");
                SetStrProp(store, aumidFmt, 5, appId);
                SetStrProp(store, aumidFmt, 4, displayName);
                if (!string.IsNullOrEmpty(exePath) && System.IO.File.Exists(exePath)) {
                    SetStrProp(store, aumidFmt, 2, "\"" + exePath + "\"");
                    SetStrProp(store, aumidFmt, 3, exePath + ",0");
                } else if (!string.IsNullOrEmpty(icoPath) && System.IO.File.Exists(icoPath)) {
                    SetStrProp(store, aumidFmt, 3, icoPath);
                }
                store.Commit();
                Marshal.ReleaseComObject(store);
            }
        } catch { }
    }
}
"@
    }
    [void][AlphaWinShellHelper]::SetCurrentProcessExplicitAppUserModelID("AlphaAlgorithms.AlphaCloudSync")
    # Register per-user AppUserModelId DisplayName & crisp PNG IconUri so Windows 11 Toasts & Taskbar show "AlphaCloudSync" + official logo
    $aumidKey = "HKCU:\Software\Classes\AppUserModelId\AlphaAlgorithms.AlphaCloudSync"
    if (-not (Test-Path -LiteralPath $aumidKey)) { New-Item -Path $aumidKey -Force | Out-Null }
    Set-ItemProperty -Path $aumidKey -Name "DisplayName" -Value "AlphaCloudSync" -Force
    Set-ItemProperty -Path $aumidKey -Name "IconBackgroundColor" -Value "0" -Force
    if (Test-Path -LiteralPath $AppLogoPngPath) {
        Set-ItemProperty -Path $aumidKey -Name "IconUri" -Value $AppLogoPngPath -Force
    }
} catch {}

# Obsidian Dark System Tray Menu Renderer + Thread-Safe Native Real-Time Folder Watcher Hub
try {
    if (-not ("AlphaDarkTrayRenderer" -as [type])) {
        Add-Type -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing") -TypeDefinition @"
using System;
using System.Drawing;
using System.Windows.Forms;

public class AlphaDarkColorTable : ProfessionalColorTable {
    public override Color MenuItemSelected { get { return Color.FromArgb(26, 43, 72); } }
    public override Color MenuItemSelectedGradientBegin { get { return Color.FromArgb(26, 43, 72); } }
    public override Color MenuItemSelectedGradientEnd { get { return Color.FromArgb(26, 43, 72); } }
    public override Color MenuItemBorder { get { return Color.FromArgb(56, 189, 248); } }
    public override Color MenuBorder { get { return Color.FromArgb(36, 53, 80); } }
    public override Color ToolStripDropDownBackground { get { return Color.FromArgb(13, 21, 36); } }
    public override Color ImageMarginGradientBegin { get { return Color.FromArgb(13, 21, 36); } }
    public override Color ImageMarginGradientMiddle { get { return Color.FromArgb(13, 21, 36); } }
    public override Color ImageMarginGradientEnd { get { return Color.FromArgb(13, 21, 36); } }
    public override Color SeparatorDark { get { return Color.FromArgb(30, 46, 71); } }
    public override Color SeparatorLight { get { return Color.FromArgb(30, 46, 71); } }
}

public class AlphaDarkTrayRenderer : ToolStripProfessionalRenderer {
    public AlphaDarkTrayRenderer() : base(new AlphaDarkColorTable()) { this.RoundedEdges = true; }
    protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e) {
        e.TextColor = e.Item.Selected ? Color.White : Color.FromArgb(226, 232, 240);
        base.OnRenderItemText(e);
    }
}
"@
    }
} catch {}

try {
    if (-not ("AlphaFolderWatchHub" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;

public class AlphaWatchFileEvent {
    public string FolderRoot;
    public string RelPath;
    public string Kind;
}

public class AlphaWatchBatch {
    public string FolderRoot;
    public string[] Files;
    public bool FullSyncRequired;
}

public class AlphaFolderWatchHub : IDisposable {
    private sealed class DirtyState {
        public DateTime LastUtc;
        public HashSet<string> Files = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        public bool FullSyncRequired;
    }

    private readonly List<FileSystemWatcher> _watchers = new List<FileSystemWatcher>();
    private readonly Dictionary<string, DirtyState> _dirty = new Dictionary<string, DirtyState>(StringComparer.OrdinalIgnoreCase);
    private readonly object _dirtyLock = new object();
    private readonly ConcurrentQueue<AlphaWatchFileEvent> _recentEvents = new ConcurrentQueue<AlphaWatchFileEvent>();
    private volatile bool _paused = false;

    public bool Paused {
        get { return _paused; }
        set { _paused = value; }
    }

    public int WatchCount {
        get { lock (_watchers) { return _watchers.Count; } }
    }

    private static bool IsIgnoredPath(string fullPath) {
        if (string.IsNullOrEmpty(fullPath)) return true;
        string low = fullPath.ToLowerInvariant().Replace('/', '\\');
        string name = Path.GetFileName(low);
        if (name == "desktop.ini" || name == "thumbs.db" || name.StartsWith("~$") ||
            name.EndsWith(".tmp") || name.EndsWith(".part") || name.EndsWith(".crdownload")) return true;
        if (low.Contains("\\.git\\") || low.EndsWith("\\.git") ||
            low.Contains("\\node_modules\\") || low.Contains("\\__pycache__\\") ||
            low.Contains("\\.venv\\") || low.Contains("\\.vs\\") ||
            low.Contains("\\.next\\") || low.Contains("\\.expo\\")) return true;
        return false;
    }

    private static string GetRelPath(string root, string fullPath) {
        if (string.IsNullOrEmpty(fullPath)) return "";
        string rNorm = root.EndsWith("\\") ? root : (root + "\\");
        if (fullPath.StartsWith(rNorm, StringComparison.OrdinalIgnoreCase)) {
            return fullPath.Substring(rNorm.Length).Replace('\\', '/');
        }
        return Path.GetFileName(fullPath);
    }

    private void RecordChange(string root, string fullPath, string kind, bool requireFullSync) {
        if (_paused) return;
        if (!string.IsNullOrEmpty(fullPath) && IsIgnoredPath(fullPath)) return;
        string rel = GetRelPath(root, fullPath);
        if (!string.IsNullOrEmpty(rel) && !Directory.Exists(fullPath)) {
            if (_recentEvents.Count < 150) {
                _recentEvents.Enqueue(new AlphaWatchFileEvent { FolderRoot = root, RelPath = rel, Kind = kind });
            }
        }
        lock (_dirtyLock) {
            DirtyState st;
            if (!_dirty.TryGetValue(root, out st)) {
                st = new DirtyState();
                _dirty[root] = st;
            }
            st.LastUtc = DateTime.UtcNow;
            if (requireFullSync || string.IsNullOrEmpty(rel) || Directory.Exists(fullPath) || st.Files.Count >= 20) {
                st.FullSyncRequired = true;
            } else {
                st.Files.Add(rel);
            }
        }
    }

    public void SetFolders(string[] folders) {
        StopAll();
        if (folders == null) return;
        lock (_watchers) {
            foreach (string raw in folders) {
                if (string.IsNullOrWhiteSpace(raw) || !Directory.Exists(raw)) continue;
                string root = raw.Length > 3 ? raw.TrimEnd('\\') : raw;
                try {
                    FileSystemWatcher fsw = new FileSystemWatcher(root);
                    fsw.IncludeSubdirectories = true;
                    fsw.NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.LastWrite | NotifyFilters.Size;
                    fsw.InternalBufferSize = 65536;
                    fsw.Created += delegate(object s, FileSystemEventArgs e) { RecordChange(root, e.FullPath, "Created", false); };
                    fsw.Changed += delegate(object s, FileSystemEventArgs e) { RecordChange(root, e.FullPath, "Changed", false); };
                    fsw.Deleted += delegate(object s, FileSystemEventArgs e) { RecordChange(root, e.FullPath, "Deleted", true); };
                    fsw.Renamed += delegate(object s, RenamedEventArgs e) {
                        if (!IsIgnoredPath(e.FullPath) || !IsIgnoredPath(e.OldFullPath)) {
                            RecordChange(root, e.FullPath, "Renamed", true);
                        }
                    };
                    fsw.Error += delegate(object s, ErrorEventArgs e) {
                        if (Directory.Exists(root)) RecordChange(root, "", "Overflow", true);
                    };
                    fsw.EnableRaisingEvents = true;
                    _watchers.Add(fsw);
                } catch { }
            }
        }
    }

    public AlphaWatchFileEvent[] PopRecentFileEvents() {
        List<AlphaWatchFileEvent> list = new List<AlphaWatchFileEvent>();
        AlphaWatchFileEvent ev;
        while (_recentEvents.TryDequeue(out ev)) { list.Add(ev); }
        return list.ToArray();
    }

    public AlphaWatchBatch[] PopSettledBatches(double quietSeconds) {
        List<AlphaWatchBatch> ready = new List<AlphaWatchBatch>();
        DateTime now = DateTime.UtcNow;
        lock (_dirtyLock) {
            List<string> doneKeys = new List<string>();
            foreach (KeyValuePair<string, DirtyState> kv in _dirty) {
                if ((now - kv.Value.LastUtc).TotalSeconds >= quietSeconds) {
                    string[] filesArr = new string[kv.Value.Files.Count];
                    kv.Value.Files.CopyTo(filesArr);
                    ready.Add(new AlphaWatchBatch {
                        FolderRoot = kv.Key,
                        Files = filesArr,
                        FullSyncRequired = kv.Value.FullSyncRequired || filesArr.Length == 0
                    });
                    doneKeys.Add(kv.Key);
                }
            }
            foreach (string dk in doneKeys) _dirty.Remove(dk);
        }
        return ready.ToArray();
    }

    public void ClearPending() {
        lock (_dirtyLock) { _dirty.Clear(); }
        AlphaWatchFileEvent dummy;
        while (_recentEvents.TryDequeue(out dummy)) { }
    }

    public void StopAll() {
        lock (_watchers) {
            foreach (FileSystemWatcher fsw in _watchers) {
                try { fsw.EnableRaisingEvents = false; fsw.Dispose(); } catch { }
            }
            _watchers.Clear();
        }
        ClearPending();
    }

    public void Dispose() {
        StopAll();
    }
}
"@
    }
} catch {}

function Load-BitmapImageNoLock {
    param([string]$FilePath)
    if ([string]::IsNullOrWhiteSpace($FilePath) -or -not (Test-Path -LiteralPath $FilePath)) { return $null }
    try {
        $bi = New-Object System.Windows.Media.Imaging.BitmapImage
        $bi.BeginInit()
        $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bi.UriSource = [Uri]::new($FilePath)
        $bi.EndInit()
        $bi.Freeze()
        return $bi
    } catch { return $null }
}

$script:AppIconSource    = Load-BitmapImageNoLock -FilePath $AppIconPath
$script:AppLogoPngSource = Load-BitmapImageNoLock -FilePath $AppLogoPngPath
if ($null -eq $script:AppLogoPngSource) { $script:AppLogoPngSource = $script:AppIconSource }

function Get-ScreenWorkAreaDip {
    param([System.Windows.Window]$Win = $null, [Nullable[double]]$HintLeftDip = $null, [Nullable[double]]$HintTopDip = $null, [double]$HintWDip = 1000, [double]$HintHDip = 680)
    $dpiX = 1.0; $dpiY = 1.0
    $src = if ($null -ne $Win) { [System.Windows.PresentationSource]::FromVisual($Win) } else { $null }
    if ($null -ne $src -and $null -ne $src.CompositionTarget) {
        $dpiX = $src.CompositionTarget.TransformToDevice.M11
        $dpiY = $src.CompositionTarget.TransformToDevice.M22
    } else {
        try {
            $g = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
            $dpiX = $g.DpiX / 96.0; $dpiY = $g.DpiY / 96.0; $g.Dispose()
        } catch {}
    }
    $targetScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    $matchedSaved = $false
    if ($null -ne $Win) {
        try {
            $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper $Win).Handle
            if ($hwnd -ne [IntPtr]::Zero) { $targetScreen = [System.Windows.Forms.Screen]::FromHandle($hwnd) }
        } catch {}
    }
    if ($null -ne $HintLeftDip -and $null -ne $HintTopDip) {
        $physRect = [System.Drawing.Rectangle]::new(
            [int]([double]$HintLeftDip * $dpiX), [int]([double]$HintTopDip * $dpiY),
            [int]([math]::Max(100.0, [double]$HintWDip) * $dpiX), [int]([math]::Max(60.0, [double]$HintHDip) * $dpiY)
        )
        foreach ($sc in [System.Windows.Forms.Screen]::AllScreens) {
            $inter = [System.Drawing.Rectangle]::Intersect($sc.WorkingArea, $physRect)
            if ($inter.Width -ge 80 -and $inter.Height -ge 40) { $targetScreen = $sc; $matchedSaved = $true; break }
        }
    }
    $wa = $targetScreen.WorkingArea
    return [PSCustomObject]@{
        Rect         = [System.Windows.Rect]::new($wa.Left / $dpiX, $wa.Top / $dpiY, $wa.Width / $dpiX, $wa.Height / $dpiY)
        DpiX         = $dpiX
        DpiY         = $dpiY
        MatchedSaved = $matchedSaved
    }
}
