# ==============================================================================
# AlphaCloudSync Module: UI.ThemeAndLayout (Obsidian Dark Control Styles, Main Studio XAML & Control Bindings)
# ==============================================================================

# Shared Native Dark WPF Controls Resource Block (ZERO White Win95 ScrollBars/ComboBoxes/CheckBoxes!)
$script:DarkControlStylesXaml = @"
        <!-- ULTRA-SLIM 6px DARK SCROLLBAR -->
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="7"/>
            <Setter Property="MinWidth" Value="7"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent" Margin="1,2">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border x:Name="ThumbBd" Background="#253650" CornerRadius="3" Margin="1,0"/>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="ThumbBd" Property="Background" Value="#3E5A82"/>
                                                    </Trigger>
                                                    <Trigger Property="IsDragging" Value="True">
                                                        <Setter TargetName="ThumbBd" Property="Background" Value="#38BDF8"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="Orientation" Value="Horizontal">
                    <Setter Property="Width" Value="Auto"/>
                    <Setter Property="MinWidth" Value="0"/>
                    <Setter Property="Height" Value="7"/>
                    <Setter Property="MinHeight" Value="7"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ScrollBar">
                                <Grid Background="Transparent" Margin="2,1">
                                    <Track x:Name="PART_Track" IsDirectionReversed="False">
                                        <Track.Thumb>
                                            <Thumb>
                                                <Thumb.Template>
                                                    <ControlTemplate TargetType="Thumb">
                                                        <Border x:Name="ThumbBd" Background="#253650" CornerRadius="3" Margin="0,1"/>
                                                        <ControlTemplate.Triggers>
                                                            <Trigger Property="IsMouseOver" Value="True">
                                                                <Setter TargetName="ThumbBd" Property="Background" Value="#3E5A82"/>
                                                            </Trigger>
                                                        </ControlTemplate.Triggers>
                                                    </ControlTemplate>
                                                </Thumb.Template>
                                            </Thumb>
                                        </Track.Thumb>
                                    </Track>
                                </Grid>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- NATIVE DARK COMBOBOX + DARK DROPDOWN POPUP -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Padding" Value="10,7"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="ItemBd" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}" CornerRadius="5" Margin="3,1">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="ItemBd" Property="Background" Value="#1B2E4B"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="ItemBd" Property="Background" Value="#163254"/>
                                <Setter Property="Foreground" Value="#38BDF8"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="#131E33"/>
            <Setter Property="BorderBrush" Value="#253652"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Padding" Value="9,0,6,0"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton x:Name="ToggleButton" Focusable="False" ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border x:Name="BoxBd" Background="{Binding Background, RelativeSource={RelativeSource AncestorType=ComboBox}}"
                                                BorderBrush="{Binding BorderBrush, RelativeSource={RelativeSource AncestorType=ComboBox}}"
                                                BorderThickness="1" CornerRadius="6">
                                            <Grid>
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="26"/>
                                                </Grid.ColumnDefinitions>
                                                <Path Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center"
                                                      Data="M 0,0 L 4,4 L 8,0" Stroke="#94A3B8" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
                                            </Grid>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter TargetName="BoxBd" Property="Background" Value="#192742"/>
                                                <Setter TargetName="BoxBd" Property="BorderBrush" Value="#38BDF8"/>
                                            </Trigger>
                                            <Trigger Property="IsChecked" Value="True">
                                                <Setter TargetName="BoxBd" Property="BorderBrush" Value="#38BDF8"/>
                                            </Trigger>
                                            <Trigger Property="IsEnabled" Value="False">
                                                <Setter TargetName="BoxBd" Property="Opacity" Value="0.45"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <ContentPresenter x:Name="ContentSite" IsHitTestVisible="False"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              Margin="10,0,28,0" VerticalAlignment="Center" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"/>
                            <Popup x:Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
                                <Border x:Name="DropDownBorder" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="260"
                                        Background="#0D1626" BorderBrush="#2A3E5E" BorderThickness="1" CornerRadius="8" Padding="0,3" Margin="0,4,0,0">
                                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                                        <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- NATIVE DARK CHECKBOX -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CBD5E1"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border x:Name="ChkBox" Width="16" Height="16" CornerRadius="4" Background="#0C1424" BorderBrush="#344B6E" BorderThickness="1.3" VerticalAlignment="Center">
                                <Path x:Name="ChkMark" Visibility="Collapsed" FlowDirection="LeftToRight" Width="10" Height="10" Stretch="Uniform"
                                      Stroke="#FFFFFF" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                      Data="M 1,5.5 L 4.2,8.8 L 9.5,2"/>
                            </Border>
                            <ContentPresenter x:Name="ChkText" Margin="7,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="Content" Value="{x:Null}">
                                <Setter TargetName="ChkText" Property="Margin" Value="0"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="ChkBox" Property="Background" Value="#0EA5E9"/>
                                <Setter TargetName="ChkBox" Property="BorderBrush" Value="#38BDF8"/>
                                <Setter TargetName="ChkMark" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ChkBox" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- NATIVE DARK TEXTBOX -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#0B1220"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="BorderBrush" Value="#253652"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CaretBrush" Value="#38BDF8"/>
            <Setter Property="SelectionBrush" Value="#1D4ED8"/>
            <Setter Property="Padding" Value="9,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="TbBd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocused" Value="True">
                                <Setter TargetName="TbBd" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="TbBd" Property="BorderBrush" Value="#3B567E"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- NATIVE DARK CONTEXT MENU -->
        <Style TargetType="ContextMenu">
            <Setter Property="Background" Value="#0E1729"/>
            <Setter Property="BorderBrush" Value="#263854"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ContextMenu">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="8" Padding="4">
                            <StackPanel IsItemsHost="True"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="MenuItem">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="MenuItem">
                        <Border x:Name="MiBd" Background="Transparent" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="MiBd" Property="Background" Value="#1B2E4B"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- NATIVE DARK DATEPICKER -->
        <Style TargetType="DatePicker">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="#0B1220"/>
            <Setter Property="BorderBrush" Value="#253652"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="DatePickerTextBox">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="#0B1220"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="CaretBrush" Value="#38BDF8"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Padding" Value="6,0"/>
        </Style>

        <!-- NATIVE DARK TOOLTIP -->
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="#0F1829"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="BorderBrush" Value="#2563EB"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToolTip">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- RESTRAINED STUDIO BUTTON SYSTEM -->
        <Style TargetType="Button">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="#162238"/>
            <Setter Property="BorderBrush" Value="#273A57"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="13,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="btnBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" RecognizesAccessKey="True"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="btnBorder" Property="Opacity" Value="0.90"/>
                                <Setter TargetName="btnBorder" Property="BorderBrush" Value="#38BDF8"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="btnBorder" Property="Opacity" Value="0.76"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="btnBorder" Property="Background" Value="#111A2B"/>
                                <Setter TargetName="btnBorder" Property="BorderBrush" Value="#1C2940"/>
                                <Setter TargetName="btnBorder" Property="Opacity" Value="0.50"/>
                                <Setter Property="Foreground" Value="#64748B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
"@

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AlphaCloudSync v1.2.8"
        WindowStyle="SingleBorderWindow"
        ResizeMode="CanResize"
        WindowStartupLocation="Manual"
        FlowDirection="LeftToRight"
        MinWidth="780" MinHeight="540"
        Background="#080D17"
        Foreground="#F8FAFC"
        FontFamily="Segoe UI">

    <Window.TaskbarItemInfo>
        <TaskbarItemInfo x:Name="TaskbarInfo" ProgressState="None" ProgressValue="0"/>
    </Window.TaskbarItemInfo>

    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="38"
                      CornerRadius="0"
                      GlassFrameThickness="0"
                      ResizeBorderThickness="7"
                      UseAeroCaptionButtons="False"/>
    </WindowChrome.WindowChrome>

    <Window.Resources>
        $($script:DarkControlStylesXaml)

        <Style x:Key="TitleBarBtnStyle" TargetType="Button">
            <Setter Property="Width" Value="42"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Focusable" Value="False"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#172338"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#22334F"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TitleBarCloseStyle" TargetType="Button" BasedOn="{StaticResource TitleBarBtnStyle}">
            <Setter Property="Width" Value="46"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#DC2626"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#B91C1C"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="NavBtnStyle" TargetType="Button">
            <Setter Property="Height" Value="38"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="12,0"/>
            <Setter Property="FontSize" Value="12.5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="NavBd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}" Margin="0,2">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="NavBd" Property="Background" Value="#131F35"/>
                                <Setter Property="Foreground" Value="#F8FAFC"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#0C1424"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="BorderBrush" Value="#1E2C42"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="RowBackground" Value="#0F1829"/>
            <Setter Property="AlternatingRowBackground" Value="#121D32"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#19263C"/>
            <Setter Property="VerticalGridLinesBrush" Value="#19263C"/>
            <Setter Property="RowHeight" Value="36"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="SelectionMode" Value="Single"/>
            <Setter Property="SelectionUnit" Value="FullRow"/>
            <Setter Property="AutoGenerateColumns" Value="False"/>
            <Setter Property="CanUserAddRows" Value="False"/>
            <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Auto"/>
        </Style>

        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#0A111F"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="Padding" Value="10,0"/>
            <Setter Property="Height" Value="34"/>
            <Setter Property="BorderBrush" Value="#1E2C42"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>

        <Style TargetType="DataGridCell">
            <Setter Property="Padding" Value="9,0"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridCell">
                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#163254"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="DataGridRow">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#172540"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#163254"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Grid>
                            <Border x:Name="PART_Track" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6"/>
                            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="6"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border x:Name="WindowOuterBorder" Background="#080D17" BorderBrush="#1F2E46" BorderThickness="1">
        <Grid x:Name="WindowShellGrid">
            <Grid.RowDefinitions>
                <RowDefinition Height="38"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- ROW 0: 38px CUSTOM OBSIDIAN TITLE BAR -->
            <Border Grid.Row="0" Background="#070C15" BorderBrush="#172236" BorderThickness="0,0,0,1">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,8,0">
                        <Image x:Name="ImgTitleIcon" FlowDirection="LeftToRight" Width="20" Height="20" Margin="0,0,9,0" RenderOptions.BitmapScalingMode="HighQuality"/>
                        <TextBlock x:Name="TxtWindowTitle" FlowDirection="LeftToRight" Text="AlphaCloudSync" FontSize="13" FontWeight="Bold" Foreground="#F1F5F9" VerticalAlignment="Center"/>
                        <Border Background="#12243D" BorderBrush="#1F3B61" BorderThickness="1" CornerRadius="4" Padding="6,1" Margin="8,0,0,0" VerticalAlignment="Center">
                            <TextBlock x:Name="TxtBrandBadge" Text="v1.2.8" FontSize="10" FontWeight="SemiBold" Foreground="#38BDF8"/>
                        </Border>
                        <TextBlock x:Name="TxtWindowSubtitle" Text="" FontSize="11.5" Foreground="#64748B" VerticalAlignment="Center" Margin="10,0,0,0"/>
                        <Button x:Name="BtnUpdateBanner" Visibility="Collapsed" Background="#064E3B" BorderBrush="#10B981" Foreground="#A7F3D0" FontSize="11" FontWeight="Bold" Padding="10,2" Height="24" Margin="12,0,0,0" VerticalAlignment="Center" Cursor="Hand">
                            <TextBlock x:Name="TxtUpdateBanner" Text="Update Available" VerticalAlignment="Center"/>
                        </Button>
                    </StackPanel>

                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button x:Name="BtnTitleTray" Style="{StaticResource TitleBarBtnStyle}" Width="38" ToolTip="Hide to Tray">
                            <Path FlowDirection="LeftToRight" Width="12" Height="12" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.3" Data="M 6,1 V 8 M 3,5.5 L 6,8.5 L 9,5.5 M 1,11 H 11"/>
                        </Button>
                        <Button x:Name="BtnTitleMin" Style="{StaticResource TitleBarBtnStyle}" ToolTip="Minimize">
                            <Path FlowDirection="LeftToRight" Width="10" Height="10" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.3" Data="M 0,5 H 10"/>
                        </Button>
                        <Button x:Name="BtnTitleMax" Style="{StaticResource TitleBarBtnStyle}" ToolTip="Maximize">
                            <Path x:Name="PathMaxIcon" FlowDirection="LeftToRight" Width="10" Height="10" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.3" Data="M 0,0 H 10 V 10 H 0 Z"/>
                        </Button>
                        <Button x:Name="BtnTitleClose" Style="{StaticResource TitleBarCloseStyle}" ToolTip="Close">
                            <Path FlowDirection="LeftToRight" Width="10" Height="10" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.3" Data="M 0,0 L 10,10 M 10,0 L 0,10"/>
                        </Button>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- ROW 1: 2-COLUMN DESKTOP STUDIO (CALM 248px SIDEBAR + FOCUSED MAIN WORKSPACE) -->
            <Grid x:Name="RootGrid" Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="248"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- SIDEBAR (#0B1220) -->
                <Border Grid.Column="0" Background="#0B1220" BorderBrush="#192438" BorderThickness="0,0,1,0" Padding="12,12">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <!-- Active Backup Account Switcher (Clean & Focused; Full Account Management lives in Settings) -->
                        <Border Grid.Row="0" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="9" Padding="10,9" Margin="0,0,0,12">
                            <StackPanel Orientation="Vertical">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,7">
                                    <Ellipse x:Name="DotAccount" Width="8" Height="8" Fill="#10B981" Margin="0,0,7,0" VerticalAlignment="Center"/>
                                    <TextBlock x:Name="TxtAccountStatus" Text="..." FontSize="11.5" FontWeight="SemiBold" Foreground="#E2E8F0" MaxWidth="185" TextTrimming="CharacterEllipsis"/>
                                </StackPanel>
                                <ComboBox x:Name="CmbAccountProfile" FlowDirection="LeftToRight" Height="28"/>
                            </StackPanel>
                        </Border>

                        <!-- 4 Clean Navigation Views (Folders, Activity, Storage & Multi-Drives, Organized Settings Gear) -->
                        <StackPanel Grid.Row="1" Orientation="Vertical" Margin="0,0,0,10">
                            <Button x:Name="BtnNavFolders" Style="{StaticResource NavBtnStyle}">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <Border x:Name="IndNavFolders" Width="3" Height="16" CornerRadius="2" Background="#38BDF8" Margin="0,0,9,0"/>
                                    <Path FlowDirection="LeftToRight" Width="15" Height="15" Stretch="Uniform" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.5" Margin="0,0,9,0" Data="M 1,3 C 1,2 2,1 3,1 H 6 L 8,3 H 13 C 14,3 15,4 15,5 V 12 C 15,13 14,14 13,14 H 3 C 2,14 1,13 1,12 Z"/>
                                    <TextBlock x:Name="TxtNavFolders" Text="Backup Folders" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>

                            <Button x:Name="BtnNavStorage" Style="{StaticResource NavBtnStyle}">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <Border x:Name="IndNavStorage" Width="3" Height="16" CornerRadius="2" Background="Transparent" Margin="0,0,9,0"/>
                                    <Path FlowDirection="LeftToRight" Width="15" Height="15" Stretch="Uniform" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.5" Margin="0,0,9,0" Data="M 2,4 H 14 V 12 H 2 Z M 5,8 H 6 M 8,8 H 12"/>
                                    <TextBlock x:Name="TxtNavStorage" Text="Drive &amp; Storage" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>

                            <Button x:Name="BtnNavActivity" Style="{StaticResource NavBtnStyle}">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <Border x:Name="IndNavActivity" Width="3" Height="16" CornerRadius="2" Background="Transparent" Margin="0,0,9,0"/>
                                    <Path FlowDirection="LeftToRight" Width="15" Height="15" Stretch="Uniform" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.5" Margin="0,0,9,0" Data="M 1,8 H 4 L 6,3 L 9,13 L 11,8 H 15"/>
                                    <TextBlock x:Name="TxtNavActivity" Text="Live Activity" VerticalAlignment="Center"/>
                                    <Ellipse x:Name="DotNavActivityLive" Width="7" Height="7" Fill="#22C55E" Margin="8,0,0,0" Visibility="Collapsed"/>
                                </StackPanel>
                            </Button>

                            <Button x:Name="BtnNavSettings" Style="{StaticResource NavBtnStyle}">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <Border x:Name="IndNavSettings" Width="3" Height="16" CornerRadius="2" Background="Transparent" Margin="0,0,9,0"/>
                                    <!-- Crisp 8-Tooth Settings Gear Icon -->
                                    <Path FlowDirection="LeftToRight" Width="15" Height="15" Stretch="Uniform" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="1.4" Margin="0,0,9,0" Data="M 8,5.2 A 2.8,2.8 0 1 0 8,10.8 A 2.8,2.8 0 1 0 8,5.2 M 8,1 V 3 M 8,13 V 15 M 1,8 H 3 M 13,8 H 15 M 3.05,3.05 L 4.46,4.46 M 11.54,11.54 L 12.95,12.95 M 12.95,3.05 L 11.54,4.46 M 4.46,11.54 L 3.05,12.95"/>
                                    <TextBlock x:Name="TxtNavSettings" Text="Settings" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                        </StackPanel>

                        <!-- Scrollable Live Accounts Status Strip (Scales cleanly to 100+ Accounts with Mouse-Wheel Scroll!) -->
                        <Border Grid.Row="2" Background="#09101D" BorderBrush="#19263C" BorderThickness="1" CornerRadius="9" Padding="7,6" Margin="0,0,0,10">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <DockPanel Grid.Row="0" LastChildFill="False" Margin="2,0,2,5">
                                    <TextBlock x:Name="TxtSidebarAccountsTitle" DockPanel.Dock="Left" Text="Accounts Overview" FontSize="10.5" FontWeight="SemiBold" Foreground="#64748B" VerticalAlignment="Center"/>
                                    <Border DockPanel.Dock="Right" Background="#122138" BorderBrush="#1E3454" BorderThickness="1" CornerRadius="8" Padding="6,0" VerticalAlignment="Center">
                                        <TextBlock x:Name="TxtSidebarAccountsCount" FlowDirection="LeftToRight" Text="0" FontSize="10" FontWeight="Bold" Foreground="#38BDF8"/>
                                    </Border>
                                </DockPanel>
                                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                    <ItemsControl x:Name="ListSidebarAccounts">
                                        <ItemsControl.ItemTemplate>
                                            <DataTemplate>
                                                <Button Uid="SidebarAccountCard" Tag="{Binding Remote}" Cursor="Hand" Margin="0,0,2,5" Padding="0" BorderThickness="0" Background="Transparent" HorizontalContentAlignment="Stretch">
                                                    <Button.Template>
                                                        <ControlTemplate TargetType="Button">
                                                            <Border x:Name="CardBd" Background="{Binding CardBg}" BorderBrush="{Binding CardBorder}" BorderThickness="1" CornerRadius="7" Padding="8,6">
                                                                <StackPanel Orientation="Vertical">
                                                                    <DockPanel LastChildFill="True" Margin="0,0,0,4">
                                                                        <Border DockPanel.Dock="Right" Visibility="{Binding DriveBadgeVis}" Background="{Binding DriveBadgeBg}" BorderBrush="{Binding DriveBadgeBorder}" BorderThickness="1" CornerRadius="4" Padding="5,0" Margin="6,0,0,0" VerticalAlignment="Center">
                                                                            <TextBlock FlowDirection="LeftToRight" Text="{Binding DriveLetter}" FontSize="10" FontWeight="Bold" Foreground="{Binding DriveBadgeFg}"/>
                                                                        </Border>
                                                                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                                                            <Ellipse Width="7" Height="7" Fill="{Binding DotBrush}" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                                                            <TextBlock FlowDirection="LeftToRight" Text="{Binding DisplayName}" FontSize="11.5" FontWeight="SemiBold" Foreground="#F1F5F9" TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
                                                                        </StackPanel>
                                                                    </DockPanel>
                                                                    <TextBlock FlowDirection="LeftToRight" Text="{Binding QuotaSummary}" FontSize="9.8" Foreground="#94A3B8" TextTrimming="CharacterEllipsis" Margin="0,0,0,3"/>
                                                                    <ProgressBar FlowDirection="LeftToRight" Height="4" Minimum="0" Maximum="100" Value="{Binding QuotaPct}" Background="#070C15" Foreground="#38BDF8" BorderBrush="#19263C"/>
                                                                    <StackPanel Orientation="Vertical" Visibility="{Binding SyncVis}" Margin="0,5,0,0">
                                                                        <TextBlock FlowDirection="LeftToRight" Text="{Binding SyncSummary}" FontSize="9.8" FontWeight="SemiBold" Foreground="#38BDF8" TextTrimming="CharacterEllipsis" Margin="0,0,0,2"/>
                                                                        <ProgressBar FlowDirection="LeftToRight" Height="4" Minimum="0" Maximum="100" Value="{Binding SyncPct}" Background="#070C15" BorderBrush="#1E3454">
                                                                            <ProgressBar.Foreground>
                                                                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                                                    <GradientStop Color="#0B6E99" Offset="0.0"/>
                                                                                    <GradientStop Color="#2196C9" Offset="0.45"/>
                                                                                    <GradientStop Color="#38BDF8" Offset="0.8"/>
                                                                                    <GradientStop Color="#8BE0FF" Offset="1.0"/>
                                                                                </LinearGradientBrush>
                                                                            </ProgressBar.Foreground>
                                                                        </ProgressBar>
                                                                    </StackPanel>
                                                                </StackPanel>
                                                            </Border>
                                                            <ControlTemplate.Triggers>
                                                                <Trigger Property="IsMouseOver" Value="True">
                                                                    <Setter TargetName="CardBd" Property="BorderBrush" Value="#38BDF8"/>
                                                                    <Setter TargetName="CardBd" Property="Background" Value="#14233C"/>
                                                                </Trigger>
                                                            </ControlTemplate.Triggers>
                                                        </ControlTemplate>
                                                    </Button.Template>
                                                </Button>
                                            </DataTemplate>
                                        </ItemsControl.ItemTemplate>
                                    </ItemsControl>
                                </ScrollViewer>
                            </Grid>
                        </Border>

                        <!-- Sidebar Quick Explorer Drive Widget -->
                        <Border Grid.Row="3" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="9" Padding="10,9" Margin="0,0,0,10">
                            <StackPanel Orientation="Vertical">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,7">
                                    <Ellipse x:Name="DotMount" Width="7" Height="7" Fill="#475569" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                    <TextBlock x:Name="TxtMountStatus" Text="..." FontSize="11" FontWeight="SemiBold" Foreground="#CBD5E1" MaxWidth="190" TextTrimming="CharacterEllipsis"/>
                                </StackPanel>
                                <Grid Margin="0,0,0,7">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="74"/>
                                        <ColumnDefinition Width="6"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <ComboBox x:Name="CmbDriveLetter" Grid.Column="0" Height="27" FontSize="11"/>
                                    <ComboBox x:Name="CmbMountMode" Grid.Column="2" Height="27">
                                        <ComboBoxItem x:Name="CbiMountStream" Content="Online Only" Tag="Stream"/>
                                        <ComboBoxItem x:Name="CbiMountMirror" Content="Offline Copy" Tag="Mirror"/>
                                        <ComboBoxItem x:Name="CbiMountUnified" Content="Show in Unified Drive" Tag="Unified"/>
                                        <ComboBoxItem x:Name="CbiMountHidden" Content="Hidden (Do not show)" Tag="Hidden"/>
                                    </ComboBox>
                                </Grid>
                                <ComboBox x:Name="CmbMountScope" Height="27" Margin="0,0,0,7">
                                    <ComboBoxItem x:Name="CbiScopeMyDrive" Content="My Drive Only" Tag="MyDrive"/>
                                    <ComboBoxItem x:Name="CbiScopeMyComputer" Content="My Computer Only" Tag="MyComputer"/>
                                    <ComboBoxItem x:Name="CbiScopeBoth" Content="My Drive + Computer" Tag="Both"/>
                                </ComboBox>
                                <Button x:Name="BtnMount" Content="Show Drive" FontSize="11.5" Padding="8,5" Background="#0E7490" BorderBrush="#06B6D4" Foreground="#FFFFFF"/>
                            </StackPanel>
                        </Border>

                        <!-- Sidebar Mini Cloud Storage Bar -->
                        <Border Grid.Row="4" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="9" Padding="10,8">
                            <StackPanel Orientation="Vertical">
                                <TextBlock x:Name="TxtSideQuotaLabel" FlowDirection="LeftToRight" TextAlignment="Center" Text="-- / --" FontSize="11" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,5" TextTrimming="CharacterEllipsis"/>
                                <ProgressBar x:Name="BarSideQuota" FlowDirection="LeftToRight" Height="6" Minimum="0" Maximum="100" Value="0" Background="#080D17" Foreground="#38BDF8" BorderBrush="#1E2C42"/>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Border>

                <!-- MAIN WORKSPACE AREA (4 CLEAN SWITCHABLE VIEWS - ZERO OUTER SCROLLBAR!) -->
                <Grid Grid.Column="1" Background="#080D17" Margin="18,14,18,12">

                    <!-- VIEW 1: BACKUP FOLDERS (DEFAULT HOME VIEW) -->
                    <Grid x:Name="PanelFolders" Visibility="Visible">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <DockPanel Grid.Row="0" LastChildFill="False" Margin="0,0,0,12">
                            <StackPanel DockPanel.Dock="Left" Orientation="Vertical">
                                <TextBlock x:Name="TxtFoldersHeader" Text="Backup Folders" FontSize="18" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock x:Name="LblFoldersSubHint" Text="" FontSize="11.5" Foreground="#64748B" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button x:Name="BtnAddFolder" DockPanel.Dock="Right" Content="+ Add Folder" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Padding="15,7" VerticalAlignment="Center"/>
                        </DockPanel>

                        <Border Grid.Row="1" Background="#0C1424" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="1">
                            <DataGrid x:Name="GridFolders" AllowDrop="True" BorderThickness="0" HorizontalScrollBarVisibility="Auto">
                                <DataGrid.ContextMenu>
                                    <ContextMenu x:Name="CtxMenuFolders">
                                        <MenuItem x:Name="CtxSyncFolder" Header="Sync"/>
                                        <MenuItem x:Name="CtxDryRunFolder" Header="Preview"/>
                                        <MenuItem x:Name="CtxRestoreFolder" Header="Restore"/>
                                        <Separator/>
                                        <MenuItem x:Name="CtxSwitchTarget" Header="Switch Location"/>
                                        <MenuItem x:Name="CtxOpenLocal" Header="Open Folder"/>
                                        <Separator/>
                                        <MenuItem x:Name="CtxRemoveFolder" Header="Remove"/>
                                    </ContextMenu>
                                </DataGrid.ContextMenu>
                                <DataGrid.Columns>
                                    <DataGridTemplateColumn Header="Include" Width="64" MinWidth="58">
                                        <DataGridTemplateColumn.CellTemplate>
                                            <DataTemplate>
                                                <CheckBox IsChecked="{Binding Enabled, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            </DataTemplate>
                                        </DataGridTemplateColumn.CellTemplate>
                                    </DataGridTemplateColumn>
                                    <DataGridTextColumn Header="Folder Name" Binding="{Binding Name}" Width="1.15*" MinWidth="105" IsReadOnly="True">
                                        <DataGridTextColumn.ElementStyle>
                                            <Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding Name}"/></Style>
                                        </DataGridTextColumn.ElementStyle>
                                    </DataGridTextColumn>
                                    <DataGridTextColumn Header="Local Path" Binding="{Binding LocalPath}" Width="1.45*" MinWidth="135" IsReadOnly="True">
                                        <DataGridTextColumn.ElementStyle>
                                            <Style TargetType="TextBlock"><Setter Property="FlowDirection" Value="LeftToRight"/><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding LocalPath}"/></Style>
                                        </DataGridTextColumn.ElementStyle>
                                    </DataGridTextColumn>
                                    <DataGridTemplateColumn Header="Drive Path" Width="1.75*" MinWidth="175">
                                        <DataGridTemplateColumn.CellTemplate>
                                            <DataTemplate>
                                                <ComboBox Uid="FolderTarget" Tag="{Binding LocalPath}" Height="27" FontSize="11.5" Margin="2,0"
                                                          FlowDirection="LeftToRight" HorizontalAlignment="Stretch" VerticalAlignment="Center"
                                                          ItemsSource="{Binding TargetOptions}" SelectedItem="{Binding SelectedTargetOption, Mode=OneWay}"
                                                          ToolTip="{Binding SelectedTargetOption.Label}">
                                                    <ComboBox.ItemTemplate>
                                                        <DataTemplate>
                                                            <TextBlock FlowDirection="LeftToRight" Text="{Binding Label}" TextTrimming="CharacterEllipsis"/>
                                                        </DataTemplate>
                                                    </ComboBox.ItemTemplate>
                                                </ComboBox>
                                            </DataTemplate>
                                        </DataGridTemplateColumn.CellTemplate>
                                    </DataGridTemplateColumn>
                                    <DataGridTextColumn Header="PC Size" Binding="{Binding LocalSizeDisplay}" Width="1.2*" MinWidth="124" IsReadOnly="True">
                                        <DataGridTextColumn.ElementStyle>
                                            <Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding LocalSizeDisplay}"/></Style>
                                        </DataGridTextColumn.ElementStyle>
                                    </DataGridTextColumn>
                                    <DataGridTextColumn Header="On Drive" Binding="{Binding RemoteSizeDisplay}" Width="1.2*" MinWidth="124" IsReadOnly="True">
                                        <DataGridTextColumn.ElementStyle>
                                            <Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RemoteSizeDisplay}"/></Style>
                                        </DataGridTextColumn.ElementStyle>
                                    </DataGridTextColumn>
                                    <DataGridTextColumn Header="Status" Binding="{Binding LastStatusDisplay}" Width="1.05*" MinWidth="106" IsReadOnly="True">
                                        <DataGridTextColumn.ElementStyle>
                                            <Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding LastStatusDisplay}"/></Style>
                                        </DataGridTextColumn.ElementStyle>
                                    </DataGridTextColumn>
                                </DataGrid.Columns>
                            </DataGrid>
                        </Border>

                        <!-- Clean Inline Folder Action Strip + Active Policy Summary -->
                        <DockPanel Grid.Row="2" LastChildFill="False" Margin="0,12,0,0">
                            <WrapPanel DockPanel.Dock="Left" Orientation="Horizontal">
                                <Button x:Name="BtnSyncSelected" Content="Sync Selected" Padding="12,6" Margin="0,2,8,2" IsEnabled="False"/>
                                <Button x:Name="BtnToggleTarget" Content="Switch Location" Padding="12,6" Margin="0,2,8,2" IsEnabled="False"/>
                                <Button x:Name="BtnRemoveFolder" Content="- Remove" Padding="12,6" Margin="0,2,8,2" IsEnabled="False"/>
                            </WrapPanel>
                            <Border DockPanel.Dock="Right" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="14" Padding="12,4" VerticalAlignment="Center">
                                <TextBlock x:Name="TxtQuickPolicyChip" Text="" FontSize="11" Foreground="#7DD3FC" FontWeight="SemiBold"/>
                            </Border>
                        </DockPanel>
                    </Grid>

                    <!-- VIEW 2: FULL-HEIGHT LIVE ACTIVITY FEED & ENGINE CONSOLE -->
                    <Grid x:Name="PanelActivity" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <DockPanel Grid.Row="0" LastChildFill="False" Margin="0,0,0,12">
                            <TextBlock x:Name="LblFeedHeader" DockPanel.Dock="Left" Text="Live File Activity" FontSize="18" FontWeight="Bold" Foreground="#F8FAFC" VerticalAlignment="Center"/>
                            <Button x:Name="BtnClearLog" DockPanel.Dock="Right" Content="Clear Log" Padding="12,5"/>
                        </DockPanel>

                        <Grid x:Name="GridBottomSplit" Grid.Row="1">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="1.45*" MinHeight="130"/>
                                <RowDefinition Height="10"/>
                                <RowDefinition Height="1*" MinHeight="110"/>
                            </Grid.RowDefinitions>

                            <!-- TOP FULL-WIDTH: LIVE FILE QUEUE (UPLOADING & COMPLETED) -->
                            <Border x:Name="CardFeed" Grid.Row="0" Background="#0C1424" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="1">
                                <DataGrid x:Name="GridActivity" RowHeight="32" FontSize="11.5" IsReadOnly="True" BorderThickness="0" HorizontalScrollBarVisibility="Auto">
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="Status" Binding="{Binding State}" Width="122" MinWidth="104">
                                            <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Foreground" Value="{Binding StateBrush}"/><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding State}"/></Style></DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                        <DataGridTextColumn Header="File Path" Binding="{Binding FileName}" Width="3*" MinWidth="240">
                                            <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="FlowDirection" Value="LeftToRight"/><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding FileName}"/></Style></DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                        <DataGridTemplateColumn Header="Progress" Width="158" MinWidth="140">
                                            <DataGridTemplateColumn.CellTemplate>
                                                <DataTemplate>
                                                    <Grid FlowDirection="LeftToRight" VerticalAlignment="Center" Margin="2,0,8,0" ToolTip="{Binding ProgressText}">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="42"/>
                                                        </Grid.ColumnDefinitions>
                                                        <ProgressBar Grid.Column="0" Height="6" Minimum="0" Maximum="100" Value="{Binding ProgressPct, Mode=OneWay}" Background="#0B1626" BorderBrush="#1B2C44" VerticalAlignment="Center" SnapsToDevicePixels="True">
                                                            <ProgressBar.Foreground>
                                                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                                    <GradientStop Color="#0E7490" Offset="0.0"/>
                                                                    <GradientStop Color="#22A7D8" Offset="0.55"/>
                                                                    <GradientStop Color="#7DD3FC" Offset="1.0"/>
                                                                </LinearGradientBrush>
                                                            </ProgressBar.Foreground>
                                                        </ProgressBar>
                                                        <TextBlock Grid.Column="1" Text="{Binding ProgressText}" FontSize="10.5" FontWeight="SemiBold" Foreground="{Binding ProgressBrush}" TextAlignment="Right" VerticalAlignment="Center"/>
                                                    </Grid>
                                                </DataTemplate>
                                            </DataGridTemplateColumn.CellTemplate>
                                        </DataGridTemplateColumn>
                                        <DataGridTextColumn Header="Progress / Action" Binding="{Binding Details}" Width="1.2*" MinWidth="120">
                                            <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding Details}"/></Style></DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                        <DataGridTextColumn Header="Time" Binding="{Binding Time}" Width="106" MinWidth="95">
                                            <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="FlowDirection" Value="LeftToRight"/><Setter Property="TextAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                    </DataGrid.Columns>
                                </DataGrid>
                            </Border>

                            <!-- DRAGGABLE HORIZONTAL SPLITTER HANDLE -->
                            <GridSplitter Grid.Row="1" Height="10" HorizontalAlignment="Stretch" VerticalAlignment="Center"
                                          ResizeDirection="Rows" ResizeBehavior="PreviousAndNext" Background="Transparent" Cursor="SizeNS">
                                <GridSplitter.Template>
                                    <ControlTemplate TargetType="GridSplitter">
                                        <Grid Background="Transparent">
                                            <Border x:Name="SplitGrip" Width="44" Height="3" CornerRadius="2" Background="#243550" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Grid>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter TargetName="SplitGrip" Property="Background" Value="#38BDF8"/>
                                                <Setter TargetName="SplitGrip" Property="Width" Value="64"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </GridSplitter.Template>
                            </GridSplitter>

                            <!-- BOTTOM FULL-WIDTH: LIVE ACTIVITY CONSOLE LOG -->
                            <Border x:Name="CardLog" Grid.Row="2" Background="#070C15" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="12,10">
                                <Grid>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
                                    <TextBlock x:Name="LblLogHeader" Grid.Row="0" Text="Activity Log" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,7"/>
                                    <TextBox x:Name="TxtLog" Grid.Row="1" FlowDirection="LeftToRight" TextAlignment="Left" Background="Transparent" Foreground="#38BDF8" BorderThickness="0"
                                             FontFamily="Consolas" FontSize="11.5" IsReadOnly="True" TextWrapping="Wrap" VerticalContentAlignment="Top"
                                             VerticalScrollBarVisibility="Auto" AcceptsReturn="True"/>
                                </Grid>
                            </Border>
                        </Grid>
                    </Grid>

                    <!-- VIEW 3: DRIVE STORAGE, TRASH MANAGER & MULTI-ACCOUNT WINDOWS DRIVES HUB -->
                    <Grid x:Name="PanelStorage" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock x:Name="TxtQuotaHeader" Grid.Row="0" Text="Google Drive Storage &amp; Trash Manager" FontSize="18" FontWeight="Bold" Foreground="#F8FAFC" Margin="0,0,0,12"/>

                        <!-- Cloud Storage & Trash Card -->
                        <Border Grid.Row="1" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,14">
                            <StackPanel Orientation="Vertical">
                                <ProgressBar x:Name="BarDriveQuota" Height="12" Minimum="0" Maximum="100" Value="0" Background="#080D17" Foreground="#38BDF8" BorderBrush="#243550" Margin="0,0,0,12"/>
                                <UniformGrid x:Name="GridQuotaMetrics" Columns="4" Margin="0,0,0,14">
                                    <TextBlock x:Name="TxtQuotaTotal" Text="--" FontSize="12" FontWeight="SemiBold" Foreground="#CBD5E1" TextTrimming="CharacterEllipsis"/>
                                    <TextBlock x:Name="TxtQuotaUsed"  Text="--" FontSize="12" FontWeight="SemiBold" Foreground="#38BDF8" TextTrimming="CharacterEllipsis"/>
                                    <TextBlock x:Name="TxtQuotaFree"  Text="--" FontSize="12" FontWeight="SemiBold" Foreground="#4ADE80" TextTrimming="CharacterEllipsis"/>
                                    <TextBlock x:Name="TxtQuotaTrash" Text="--" FontSize="12" FontWeight="SemiBold" Foreground="#FBBF24" TextTrimming="CharacterEllipsis"/>
                                </UniformGrid>
                                <WrapPanel Orientation="Horizontal">
                                    <Button x:Name="BtnRefreshQuota" Content="Check Space" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnCleanArchive" Content="Clean Archive" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnOpenDriveWeb" Content="Open Drive" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnEmptyDriveTrash" Content="Empty Trash" Background="#991B1B" BorderBrush="#DC2626" Foreground="#FFFFFF" Margin="0,2,0,2"/>
                                </WrapPanel>
                            </StackPanel>
                        </Border>

                        <!-- Multi-Account Windows Explorer Drives Hub (Mount 5+ Accounts Simultaneously!) -->
                        <Border Grid.Row="2" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <TextBlock x:Name="TxtMultiDriveTitle" Grid.Row="0" Text="Multi-Account Windows Drives" FontSize="14.5" FontWeight="Bold" Foreground="#F8FAFC" Margin="0,0,0,4"/>
                                <TextBlock x:Name="TxtMultiDriveDesc" Grid.Row="1" Text="" FontSize="11.5" Foreground="#94A3B8" TextWrapping="Wrap" Margin="0,0,0,9"/>
                                <WrapPanel Grid.Row="2" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,10">
                                    <TextBlock x:Name="LblDriveLayout" Text="Windows Drive Layout:" FontSize="12" FontWeight="SemiBold" Foreground="#CBD5E1" VerticalAlignment="Center" Margin="0,2,10,2"/>
                                    <ComboBox x:Name="CmbDriveLayout" Width="375" Height="29" Margin="0,2,0,2">
                                        <ComboBoxItem x:Name="CbiLayoutSeparate" Content="Separate Drive per Account" Tag="Separate"/>
                                        <ComboBoxItem x:Name="CbiLayoutUnified" Content="Single Unified Drive (Combined Real Space)" Tag="Unified"/>
                                    </ComboBox>
                                </WrapPanel>
                                <DataGrid x:Name="GridMultiDrives" Grid.Row="3" RowHeight="40" IsReadOnly="True" HorizontalScrollBarVisibility="Auto" Margin="0,0,0,12">
                                    <DataGrid.ContextMenu>
                                        <ContextMenu x:Name="CtxMenuDrives">
                                            <MenuItem x:Name="CtxDriveToggle" Header="Show / Hide This Account Only"/>
                                            <Separator/>
                                            <MenuItem x:Name="CtxDriveUnified" Header="Show in Unified Drive"/>
                                            <MenuItem x:Name="CtxDriveSeparate" Header="Show as Separate Drive"/>
                                            <MenuItem x:Name="CtxDriveHide" Header="Hide / Exclude from Windows"/>
                                            <Separator/>
                                            <MenuItem x:Name="CtxDriveRename" Header="Rename Account"/>
                                        </ContextMenu>
                                    </DataGrid.ContextMenu>
                                    <DataGrid.ColumnHeaderStyle>
                                        <Style TargetType="DataGridColumnHeader" BasedOn="{StaticResource {x:Type DataGridColumnHeader}}">
                                            <Setter Property="HorizontalContentAlignment" Value="Center"/>
                                        </Style>
                                    </DataGrid.ColumnHeaderStyle>
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="Account Profile" Binding="{Binding DisplayName}" Width="1.1*" MinWidth="102">
                                            <DataGridTextColumn.ElementStyle>
                                                <Style TargetType="TextBlock">
                                                    <Setter Property="FlowDirection" Value="LeftToRight"/>
                                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                                    <Setter Property="TextAlignment" Value="Center"/>
                                                    <Setter Property="FontWeight" Value="SemiBold"/>
                                                    <Setter Property="Foreground" Value="#F8FAFC"/>
                                                    <Setter Property="TextTrimming" Value="CharacterEllipsis"/>
                                                    <Setter Property="ToolTip" Value="{Binding DisplayName}"/>
                                                </Style>
                                            </DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                        <DataGridTemplateColumn Header="Drive Letter" Width="0.82*" MinWidth="88">
                                            <DataGridTemplateColumn.CellTemplate>
                                                <DataTemplate>
                                                    <ComboBox Uid="DriveLetter" Tag="{Binding Remote}" Width="78" Height="28" FontSize="11.2" FontWeight="Bold" Foreground="{Binding LetterBrush}"
                                                              FlowDirection="LeftToRight" HorizontalAlignment="Center" VerticalAlignment="Center" HorizontalContentAlignment="Center"
                                                              ItemsSource="{Binding AvailableLetters}" SelectedItem="{Binding SelectedLetter, Mode=OneWay}"/>
                                                </DataTemplate>
                                            </DataGridTemplateColumn.CellTemplate>
                                        </DataGridTemplateColumn>
                                        <DataGridTemplateColumn Header="Backup Target" Width="1.35*" MinWidth="152">
                                            <DataGridTemplateColumn.CellTemplate>
                                                <DataTemplate>
                                                    <ComboBox Uid="BackupTarget" Tag="{Binding Remote}" Width="142" Height="28" FontSize="11.5"
                                                              HorizontalAlignment="Center" VerticalAlignment="Center" HorizontalContentAlignment="Center"
                                                              ItemsSource="{Binding TargetOptions}" SelectedItem="{Binding SelectedTargetOption, Mode=OneWay}">
                                                        <ComboBox.ItemTemplate>
                                                            <DataTemplate>
                                                                <TextBlock Text="{Binding Label}" TextAlignment="Center" TextTrimming="CharacterEllipsis"/>
                                                            </DataTemplate>
                                                        </ComboBox.ItemTemplate>
                                                    </ComboBox>
                                                </DataTemplate>
                                            </DataGridTemplateColumn.CellTemplate>
                                        </DataGridTemplateColumn>
                                        <DataGridTemplateColumn Header="Drive View" Width="1.25*" MinWidth="136">
                                            <DataGridTemplateColumn.CellTemplate>
                                                <DataTemplate>
                                                    <ComboBox Uid="MountScope" Tag="{Binding Remote}" Width="126" Height="28" FontSize="11.5"
                                                              HorizontalAlignment="Center" VerticalAlignment="Center" HorizontalContentAlignment="Center"
                                                              ItemsSource="{Binding ScopeOptions}" SelectedItem="{Binding SelectedScopeOption, Mode=OneWay}">
                                                        <ComboBox.ItemTemplate>
                                                            <DataTemplate>
                                                                <TextBlock Text="{Binding Label}" TextAlignment="Center" TextTrimming="CharacterEllipsis"/>
                                                            </DataTemplate>
                                                        </ComboBox.ItemTemplate>
                                                    </ComboBox>
                                                </DataTemplate>
                                            </DataGridTemplateColumn.CellTemplate>
                                        </DataGridTemplateColumn>
                                        <DataGridTextColumn Header="Mode" Binding="{Binding ModeDisplay}" Width="1.05*" MinWidth="112">
                                            <DataGridTextColumn.ElementStyle>
                                                <Style TargetType="TextBlock">
                                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                                    <Setter Property="TextAlignment" Value="Center"/>
                                                    <Setter Property="TextTrimming" Value="CharacterEllipsis"/>
                                                    <Setter Property="ToolTip" Value="{Binding ModeDisplay}"/>
                                                </Style>
                                            </DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                        <DataGridTextColumn Header="Status" Binding="{Binding StatusShort}" Width="0.8*" MinWidth="76">
                                            <DataGridTextColumn.ElementStyle>
                                                <Style TargetType="TextBlock">
                                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                                    <Setter Property="TextAlignment" Value="Center"/>
                                                    <Setter Property="FontWeight" Value="Bold"/>
                                                    <Setter Property="Foreground" Value="{Binding StatusBrush}"/>
                                                    <Setter Property="ToolTip" Value="{Binding StatusDisplay}"/>
                                                </Style>
                                            </DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                    </DataGrid.Columns>
                                </DataGrid>
                                <WrapPanel Grid.Row="4" Orientation="Horizontal">
                                    <Button x:Name="BtnMountAll" Content="Mount All Accounts" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnUnmountAll" Content="Hide All Drives" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnToggleDriveRow" Content="Show / Hide Selected" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnRenameAccount" Content="Rename Account" Margin="0,2,8,2"/>
                                    <Button x:Name="BtnCloudTransfer" Content="Cloud-to-Cloud Transfer" Background="#065F46" BorderBrush="#10B981" Foreground="#FFFFFF" Margin="0,2,0,2"/>
                                </WrapPanel>
                            </Grid>
                        </Border>
                    </Grid>

                    <!-- VIEW 4: TABBED SETTINGS CONTROL CENTER (5 ORGANIZED SUB-TABS READY FOR MULTI-PROVIDER EXPANSION) -->
                    <ScrollViewer x:Name="PanelSettings" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                        <StackPanel Orientation="Vertical" Margin="0,0,6,8">
                            <DockPanel LastChildFill="False" Margin="0,0,0,12">
                                <TextBlock x:Name="TxtSettingsPageTitle" DockPanel.Dock="Left" Text="Settings" FontSize="18" FontWeight="Bold" Foreground="#F8FAFC" VerticalAlignment="Center"/>
                                <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock x:Name="TxtUpdateStatus" Text="" FontSize="11.5" Foreground="#34D399" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                    <Button x:Name="BtnCheckUpdates" Content="Check for Updates" Background="#122138" BorderBrush="#284268" Foreground="#38BDF8" FontSize="11.5" Padding="11,5"/>
                                </StackPanel>
                            </DockPanel>

                            <!-- SETTINGS HORIZONTAL SUB-TAB BAR -->
                            <Border Background="#0A101D" BorderBrush="#19263C" BorderThickness="1" CornerRadius="9" Padding="6,5" Margin="0,0,0,14">
                                <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <Button x:Name="BtnSetTabAccounts" Content="Accounts &amp; Connections" Background="#13233A" BorderBrush="#38BDF8" Foreground="#F8FAFC" FontSize="12" FontWeight="SemiBold" Padding="13,6" Margin="0,2,6,2"/>
                                    <Button x:Name="BtnSetTabSync" Content="Sync Safety &amp; Performance" Background="#0B1322" BorderBrush="#1E2C42" Foreground="#94A3B8" FontSize="12" FontWeight="SemiBold" Padding="13,6" Margin="0,2,6,2"/>
                                    <Button x:Name="BtnSetTabBackup" Content="Schedule &amp; Skip Rules" Background="#0B1322" BorderBrush="#1E2C42" Foreground="#94A3B8" FontSize="12" FontWeight="SemiBold" Padding="13,6" Margin="0,2,6,2"/>
                                    <Button x:Name="BtnSetTabGeneral" Content="General &amp; Interface" Background="#0B1322" BorderBrush="#1E2C42" Foreground="#94A3B8" FontSize="12" FontWeight="SemiBold" Padding="13,6" Margin="0,2,6,2"/>
                                    <Button x:Name="BtnSetTabNotif" Content="Windows Notifications" Background="#0B1322" BorderBrush="#1E2C42" Foreground="#94A3B8" FontSize="12" FontWeight="SemiBold" Padding="13,6" Margin="0,2,0,2"/>
                                </WrapPanel>
                            </Border>

                            <!-- TAB 1: ACCOUNTS & CONNECTIONS -->
                            <Border x:Name="CardSetAccounts" Visibility="Visible" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,12">
                                <StackPanel Orientation="Vertical">
                                    <DockPanel LastChildFill="False" Margin="0,0,0,10">
                                        <StackPanel DockPanel.Dock="Left" Orientation="Horizontal" VerticalAlignment="Center">
                                            <TextBlock x:Name="TxtSettingsSecAccounts" Text="Accounts &amp; Connections" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                            <Border Background="#162A48" BorderBrush="#25477B" BorderThickness="1" CornerRadius="4" Padding="6,1" VerticalAlignment="Center">
                                                <TextBlock x:Name="TxtSettingsAccountsCount" Text="0" FontSize="11" FontWeight="Bold" Foreground="#38BDF8"/>
                                            </Border>
                                        </StackPanel>
                                        <WrapPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                                            <Button x:Name="BtnAddAccount" Content="+ Add Account" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" FontWeight="Bold" Padding="12,5" Margin="0,2,8,2"/>
                                            <Button x:Name="BtnCloudTransferSet" Content="Cloud-to-Cloud Transfer" Background="#065F46" BorderBrush="#10B981" Foreground="#FFFFFF" Padding="11,5" Margin="0,2,8,2"/>
                                            <Button x:Name="BtnCustomClientId" Content="Faster Mode" FontSize="11.5" Padding="10,5" Margin="0,2,0,2"/>
                                        </WrapPanel>
                                    </DockPanel>

                                    <TextBlock x:Name="TxtAccountsListHint" Text="All connected cloud accounts. The highlighted card with blue border is your active default account." FontSize="11.5" Foreground="#94A3B8" Margin="0,0,0,12" TextWrapping="Wrap"/>

                                    <!-- ACCOUNTS STACKED VERTICAL CARDS (ONE UNDER ANOTHER) -->
                                    <ItemsControl x:Name="ListSettingsAccounts">
                                        <ItemsControl.ItemTemplate>
                                            <DataTemplate>
                                                <Border Background="{Binding CardBg}" BorderBrush="{Binding CardBorder}" BorderThickness="{Binding CardBorderThickness}" CornerRadius="9" Padding="14,12" Margin="0,0,0,8">
                                                    <Grid>
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="Auto"/>
                                                        </Grid.ColumnDefinitions>

                                                        <!-- Account Info (Left) -->
                                                        <StackPanel Grid.Column="0" Orientation="Vertical" VerticalAlignment="Center">
                                                            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,4">
                                                                <Ellipse Width="10" Height="10" Fill="{Binding DotBrush}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                                                <TextBlock Text="{Binding DisplayName}" FontSize="13.5" FontWeight="Bold" Foreground="#F8FAFC" VerticalAlignment="Center"/>
                                                                <!-- Active Default Badge -->
                                                                <Border Visibility="{Binding DefaultBadgeVis}" Background="#064E3B" BorderBrush="#10B981" BorderThickness="1" CornerRadius="4" Padding="7,2" Margin="10,0,0,0" VerticalAlignment="Center">
                                                                    <TextBlock Text="{Binding DefaultBadgeText}" FontSize="11" FontWeight="Bold" Foreground="#6EE7B7"/>
                                                                </Border>
                                                                <!-- Drive Letter Badge if mounted -->
                                                                <Border Visibility="{Binding DriveBadgeVis}" Background="{Binding DriveBadgeBg}" BorderBrush="{Binding DriveBadgeBorder}" BorderThickness="1" CornerRadius="4" Padding="6,1" Margin="8,0,0,0" VerticalAlignment="Center">
                                                                    <TextBlock FlowDirection="LeftToRight" Text="{Binding DriveLetter}" FontSize="10.5" FontWeight="Bold" Foreground="{Binding DriveBadgeFg}"/>
                                                                </Border>
                                                            </StackPanel>

                                                            <WrapPanel Orientation="Horizontal" Margin="18,0,0,0">
                                                                <TextBlock Text="{Binding QuotaSummary}" FontSize="11.5" Foreground="#94A3B8" Margin="0,0,12,0"/>
                                                                <TextBlock Text="{Binding RemoteLabel}" FontSize="11" Foreground="#64748B"/>
                                                            </WrapPanel>
                                                        </StackPanel>

                                                        <!-- Actions (Right) -->
                                                        <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                                                            <!-- Interactive Connection Status / Reconnect Button -->
                                                            <Button Uid="BtnReconnectAccount" Tag="{Binding Remote}" Content="{Binding ConnStatusBtnText}" ToolTip="{Binding ConnStatusToolTip}" Background="{Binding ConnStatusBtnBg}" BorderBrush="{Binding ConnStatusBtnBorder}" Foreground="{Binding ConnStatusBtnFg}" FontSize="11.5" FontWeight="Bold" Padding="10,5" Margin="0,2,8,2" Cursor="Hand"/>
                                                            <!-- Set as Default Button (Visible only when NOT default) -->
                                                            <Button Uid="BtnSetDefaultAccount" Tag="{Binding Remote}" Visibility="{Binding SetDefaultBtnVis}" Content="{Binding SetDefaultBtnText}" ToolTip="{Binding SetDefaultToolTip}" Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" FontSize="11.5" FontWeight="SemiBold" Padding="11,5" Margin="0,2,8,2" Cursor="Hand"/>
                                                            <!-- Current Default Indicator (Visible only when IS default) -->
                                                            <Border Visibility="{Binding ActiveBtnVis}" Background="#0C2542" BorderBrush="#38BDF8" BorderThickness="1" CornerRadius="5" Padding="10,5" Margin="0,2,8,2">
                                                                <TextBlock Text="{Binding ActiveStatusText}" FontSize="11.5" FontWeight="Bold" Foreground="#38BDF8"/>
                                                            </Border>
                                                            <!-- Open Web Button -->
                                                            <Button Uid="BtnOpenWebAccount" Tag="{Binding Remote}" Content="{Binding OpenWebBtnText}" Background="#162238" BorderBrush="#253A5A" Foreground="#CBD5E1" FontSize="11.5" Padding="9,5" Margin="0,2,8,2" Cursor="Hand"/>
                                                            <!-- Sign Out / Disconnect Button -->
                                                            <Button Uid="BtnSignOutAccount" Tag="{Binding Remote}" Content="{Binding SignOutBtnText}" Background="#3A171E" BorderBrush="#991B1B" Foreground="#FCA5A5" FontSize="11.5" Padding="9,5" Margin="0,2,0,2" Cursor="Hand"/>
                                                        </WrapPanel>
                                                    </Grid>
                                                </Border>
                                            </DataTemplate>
                                        </ItemsControl.ItemTemplate>
                                    </ItemsControl>
                                </StackPanel>
                            </Border>

                            <!-- TAB 4: GENERAL & INTERFACE (LANGUAGE, CLOUD ISLAND, WINDOWS STARTUP) -->
                            <Border x:Name="CardSetGeneral" Visibility="Collapsed" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,12">
                                <StackPanel Orientation="Vertical">
                                    <TextBlock x:Name="TxtSettingsSecGeneral" Text="General &amp; Interface" FontSize="13.5" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,11"/>
                                    <WrapPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,12">
                                        <TextBlock x:Name="LblLanguage" Text="Interface Language:" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,4,10,4"/>
                                        <ComboBox x:Name="CmbLanguage" Width="195" Height="30" Margin="0,2,18,2">
                                            <ComboBoxItem Content="English" Tag="en" FlowDirection="LeftToRight"/>
                                            <ComboBoxItem Content="&#x0627;&#x0644;&#x0639;&#x0631;&#x0628;&#x064A;&#x0629;" Tag="ar" FlowDirection="RightToLeft"/>
                                            <ComboBoxItem Content="Espa&#x00F1;ol" Tag="es" FlowDirection="LeftToRight"/>
                                            <ComboBoxItem Content="Fran&#x00E7;ais" Tag="fr" FlowDirection="LeftToRight"/>
                                            <ComboBoxItem Content="Deutsch" Tag="de" FlowDirection="LeftToRight"/>
                                            <ComboBoxItem Content="&#x4E2D;&#x6587; (&#x7B80;&#x4F53;)" Tag="zh" FlowDirection="LeftToRight"/>
                                            <ComboBoxItem Content="Bahasa Indonesia" Tag="id" FlowDirection="LeftToRight"/>
                                        </ComboBox>
                                        <TextBlock x:Name="LblDriveLayoutSet" Text="Windows Drive Layout:" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,4,10,4"/>
                                        <ComboBox x:Name="CmbDriveLayoutSettings" Width="365" Height="30" Margin="0,2,0,2">
                                            <ComboBoxItem x:Name="CbiLayoutSetSeparate" Content="Separate Drive per Account" Tag="Separate"/>
                                            <ComboBoxItem x:Name="CbiLayoutSetUnified" Content="Single Unified Drive (Combined Real Space)" Tag="Unified"/>
                                        </ComboBox>
                                    </WrapPanel>
                                    <Border BorderBrush="#19263C" BorderThickness="0,1,0,0" Padding="0,11,0,0">
                                        <StackPanel Orientation="Vertical">
                                            <CheckBox x:Name="ChkCloudIsland" Content="Show Dynamic Cloud Island (Draggable floating pill)" FontSize="12.5" Margin="0,0,0,10"/>
                                            <CheckBox x:Name="ChkStartup" Content="Start with Windows (Quiet)" FontSize="12.5" Margin="0,0,0,10"/>
                                            <CheckBox x:Name="ChkFolderBadges" Content="Show AlphaCloudSync icon badge on synced Windows folders &amp; cloud drives" FontSize="12.5" Margin="0,0,0,10"/>
                                            <CheckBox x:Name="ChkExplorerMenu" Content="Show AlphaCloudSync menu on Windows folder right-click" FontSize="12.5"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </Border>

                            <!-- TAB 5: WINDOWS NOTIFICATIONS CONTROL -->
                            <Border x:Name="CardSetNotif" Visibility="Collapsed" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,12">
                                <StackPanel Orientation="Vertical">
                                    <TextBlock x:Name="TxtSettingsSecNotifications" Text="Windows Notifications" FontSize="13.5" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,10"/>
                                    <CheckBox x:Name="ChkNotifMaster" Content="Enable Windows desktop notifications" FontSize="12.5" FontWeight="SemiBold" Margin="0,0,0,10"/>
                                    <Border x:Name="PnlNotifSub" BorderBrush="#19263C" BorderThickness="0,1,0,0" Padding="18,10,0,0">
                                        <UniformGrid Columns="2">
                                            <CheckBox x:Name="ChkNotifManual"      Content="Manual sync, preview, restore &amp; trash" FontSize="12" Margin="0,0,12,8"/>
                                            <CheckBox x:Name="ChkNotifAutoSync"    Content="Real-time auto-sync (only when files actually change)" FontSize="12" Margin="0,0,0,8"/>
                                            <CheckBox x:Name="ChkNotifErrors"      Content="Sync errors &amp; warnings" FontSize="12" Margin="0,0,12,2"/>
                                            <CheckBox x:Name="ChkNotifDriveEvents" Content="Virtual drive mount &amp; unmount alerts" FontSize="12" Margin="0,0,0,2"/>
                                        </UniformGrid>
                                    </Border>
                                </StackPanel>
                            </Border>

                            <!-- TAB 3: SCHEDULE & SKIP RULES -->
                            <Border x:Name="CardSetBackup" Visibility="Collapsed" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,12">
                                <StackPanel Orientation="Vertical">
                                    <TextBlock x:Name="TxtSettingsSecBackup" Text="Schedule &amp; Skip Rules" FontSize="13.5" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,11"/>
                                    <DockPanel LastChildFill="False" Margin="0,0,0,12">
                                        <StackPanel DockPanel.Dock="Left" Orientation="Vertical" VerticalAlignment="Center">
                                            <TextBlock x:Name="LblSchedule" Text="Auto-Backup Schedule:" FontWeight="SemiBold" FontSize="12.5" Foreground="#E2E8F0" Margin="0,0,0,3"/>
                                            <TextBlock x:Name="TxtScheduleStatus" Text="..." FontSize="11.5" Foreground="#94A3B8" TextWrapping="Wrap"/>
                                        </StackPanel>
                                        <WrapPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                                            <Button x:Name="BtnOpenScheduler" Content="Set Schedule..." Background="#0284C7" BorderBrush="#38BDF8" Foreground="#FFFFFF" Margin="0,2,8,2"/>
                                            <Button x:Name="BtnDisableSchedule" Content="Turn Off" Background="#991B1B" BorderBrush="#DC2626" Foreground="#FFFFFF" Margin="0,2,0,2" Visibility="Collapsed"/>
                                        </WrapPanel>
                                    </DockPanel>
                                    <Border BorderBrush="#19263C" BorderThickness="0,1,0,0" Padding="0,11,0,12">
                                        <StackPanel Orientation="Vertical">
                                            <CheckBox x:Name="ChkAutoWatchSync" Content="Real-Time Auto-Sync" FontSize="12.5" FontWeight="SemiBold" Margin="0,0,0,4"/>
                                            <TextBlock x:Name="TxtAutoWatchStatus" Text="..." FontSize="11.5" Foreground="#94A3B8" TextWrapping="Wrap" Margin="23,0,0,0"/>
                                        </StackPanel>
                                    </Border>
                                    <Border BorderBrush="#19263C" BorderThickness="0,1,0,0" Padding="0,12,0,0">
                                        <StackPanel Orientation="Vertical">
                                            <WrapPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,10">
                                                <CheckBox x:Name="ChkJsonRules" Content="Skip Rules" IsChecked="True" FontWeight="Bold" Margin="0,4,14,4"/>
                                                <ComboBox x:Name="CmbJsonPreset" Width="230" Margin="0,2,8,2">
                                                    <ComboBoxItem x:Name="CbiPresetDev" Content="Developer" Tag="dev"/>
                                                    <ComboBoxItem x:Name="CbiPresetCreative" Content="Creative" Tag="creative"/>
                                                    <ComboBoxItem x:Name="CbiPresetGeneral" Content="General" Tag="general"/>
                                                    <ComboBoxItem x:Name="CbiPresetCustom" Content="Custom" Tag="custom"/>
                                                </ComboBox>
                                                <Button x:Name="BtnEditJsonRules" Content="Edit Rules" Margin="0,2,8,2"/>
                                                <Button x:Name="BtnLoadJsonRules" Content="Import..." Margin="0,2,8,2"/>
                                                <Button x:Name="BtnPickExclusions" Content="+ Manual Exclusions..." Background="#172554" BorderBrush="#3B82F6" Foreground="#93C5FD" FontWeight="SemiBold" Margin="0,2,0,2" Cursor="Hand"/>
                                            </WrapPanel>
                                            <WrapPanel Orientation="Horizontal">
                                                <Border x:Name="PillSavedSpace" Background="#0F291E" BorderBrush="#10B981" BorderThickness="1" CornerRadius="12" Padding="10,3" Margin="0,2,8,2" Visibility="Collapsed">
                                                    <TextBlock x:Name="TxtSavedSpace" Text="" FontSize="11.5" Foreground="#4ADE80" FontWeight="Bold"/>
                                                </Border>
                                                <Border Background="#122138" BorderBrush="#1E3454" BorderThickness="1" CornerRadius="12" Padding="11,3" Margin="0,2,0,2">
                                                    <TextBlock x:Name="TxtRulesSummary" Text="" FontSize="11.5" Foreground="#7DD3FC" FontWeight="SemiBold"/>
                                                </Border>
                                            </WrapPanel>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </Border>

                            <!-- TAB 2: SYNC SAFETY & PERFORMANCE -->
                            <Border x:Name="CardSetSync" Visibility="Collapsed" Background="#0F1829" BorderBrush="#1E2C42" BorderThickness="1" CornerRadius="10" Padding="16,14">
                                <StackPanel Orientation="Vertical">
                                    <TextBlock x:Name="TxtSettingsSecSync" Text="Sync Safety &amp; Performance" FontSize="13.5" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,11"/>
                                    <WrapPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,8">
                                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,2,16,4">
                                            <TextBlock x:Name="LblDeletePolicy" Text="When Deleted:" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                            <ComboBox x:Name="CmbDeletePolicy" Width="210">
                                                <ComboBoxItem x:Name="CbiPolicySafe" Content="Safe Archive" Tag="Safe Archive"/>
                                                <ComboBoxItem x:Name="CbiPolicyCopy" Content="Copy Only" Tag="Copy-Only"/>
                                                <ComboBoxItem x:Name="CbiPolicyMirror" Content="Exact Match" Tag="Strict Mirror"/>
                                            </ComboBox>
                                        </StackPanel>
                                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,2,16,4">
                                            <TextBlock x:Name="LblDefaultTarget" Text="Backup Destination:" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                            <ComboBox x:Name="CmbDefaultTarget" Width="170">
                                                <ComboBoxItem x:Name="CbiDefTargetDrive" Content="My Drive" Tag="My Drive"/>
                                                <ComboBoxItem x:Name="CbiDefTargetComp" Content="My Computer" Tag="My Computer"/>
                                            </ComboBox>
                                        </StackPanel>
                                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,2,0,4">
                                            <TextBlock x:Name="LblMyComputer" Text="PC Name:" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                            <TextBox x:Name="TxtComputerLabel" Text="My Computer" Width="145" Height="30"/>
                                        </StackPanel>
                                    </WrapPanel>
                                    <TextBlock x:Name="TxtDeletePolicyHint" Text="" FontSize="11.5" Foreground="#94A3B8" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                    <Border BorderBrush="#19263C" BorderThickness="0,1,0,0" Padding="0,11,0,0">
                                        <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                                            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,2,20,4">
                                                <TextBlock x:Name="LblSpeedMode" Text="Upload Speed:" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                                <ComboBox x:Name="CmbSpeedPreset" Width="190">
                                                    <ComboBoxItem x:Name="CbiSpeedTurbo" Content="Fast (Turbo)" Tag="Turbo"/>
                                                    <ComboBoxItem x:Name="CbiSpeedBalanced" Content="Balanced" Tag="Balanced"/>
                                                    <ComboBoxItem x:Name="CbiSpeedEco" Content="Gentle" Tag="Eco"/>
                                                </ComboBox>
                                            </StackPanel>
                                            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,2,0,4">
                                                <TextBlock x:Name="LblMaxDelete" Text="Delete Safety Limit (Exact Match):" Foreground="#CBD5E1" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                                <ComboBox x:Name="CmbMaxDelete" Width="210">
                                                    <ComboBoxItem x:Name="CbiMaxDelUnlimited" Content="No Limit (Unlimited)" Tag="0"/>
                                                    <ComboBoxItem x:Name="CbiMaxDel200" Content="Up to 200 files" Tag="200"/>
                                                    <ComboBoxItem x:Name="CbiMaxDel500" Content="Up to 500 files" Tag="500"/>
                                                    <ComboBoxItem x:Name="CbiMaxDel1000" Content="Up to 1,000 files" Tag="1000"/>
                                                    <ComboBoxItem x:Name="CbiMaxDel5000" Content="Up to 5,000 files" Tag="5000"/>
                                                </ComboBox>
                                            </StackPanel>
                                        </WrapPanel>
                                    </Border>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
            </Grid>

            <!-- ROW 2: DOCKED BOTTOM ACTION & RAINBOW SPECTRUM PROGRESS BAR -->
            <Border Grid.Row="2" Background="#0B1220" BorderBrush="#192438" BorderThickness="0,1,0,0" Padding="18,11">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0" Margin="0,0,0,9">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="1.45*"/>
                            <ColumnDefinition Width="1.15*"/>
                            <ColumnDefinition Width="0.95*"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="BtnSyncToggle" Grid.Column="0" Background="#10B981" BorderBrush="#34D399" Foreground="#FFFFFF" FontWeight="Bold" FontSize="13" MinHeight="38" Margin="0,0,10,0">
                            <TextBlock x:Name="TxtSyncToggle" Text="START BACKUP" TextWrapping="Wrap" TextAlignment="Center"/>
                        </Button>
                        <Button x:Name="BtnDryRun" Grid.Column="1" MinHeight="38" Margin="0,0,10,0">
                            <TextBlock x:Name="TxtDryRun" Text="Preview Only" TextWrapping="Wrap" TextAlignment="Center"/>
                        </Button>
                        <Button x:Name="BtnRestore" Grid.Column="2" MinHeight="38">
                            <TextBlock x:Name="TxtRestore" Text="Safe Restore" TextWrapping="Wrap" TextAlignment="Center"/>
                        </Button>
                    </Grid>

                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="1.15*" MinWidth="180" MaxWidth="360"/>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="1.8*"/>
                        </Grid.ColumnDefinitions>
                        <Grid Grid.Column="0" Margin="0,0,14,0" FlowDirection="LeftToRight">
                            <ProgressBar x:Name="BarSyncProgress" Height="18" Minimum="0" Maximum="100" Value="0" Background="#080D17" BorderBrush="#23344F">
                                <ProgressBar.Foreground>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#0B6E99" Offset="0.0"/>
                                        <GradientStop Color="#2196C9" Offset="0.42"/>
                                        <GradientStop Color="#38BDF8" Offset="0.78"/>
                                        <GradientStop Color="#8BE0FF" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </ProgressBar.Foreground>
                            </ProgressBar>
                            <TextBlock x:Name="TxtProgressPct" Text="0.0%" FontSize="10.5" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock x:Name="TxtUploadCounters" Grid.Column="1" Text="" FontSize="11.5" FontWeight="SemiBold" Foreground="#4ADE80" VerticalAlignment="Center" Margin="0,0,14,0"/>
                        <TextBlock x:Name="TxtLiveTransfer" Grid.Column="2" Text="" FontSize="11.5" FontWeight="SemiBold" Foreground="#94A3B8" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                    </Grid>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

if ($null -ne $script:AppLogoPngSource) { $window.Icon = $script:AppLogoPngSource }
elseif ($null -ne $script:AppIconSource) { $window.Icon = $script:AppIconSource }

$window.Add_SourceInitialized({
    try {
        $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper $window).Handle
        [AlphaWinShellHelper]::ApplyTaskbarIdentity($hwnd, "AlphaAlgorithms.AlphaCloudSync", $AppIconPath, $(if ($AppLaunchExe) { $AppLaunchExe } else { "" }), "AlphaCloudSync")
    } catch {}
})

$TaskbarInfo        = $window.FindName("TaskbarInfo")
$WindowOuterBorder  = $window.FindName("WindowOuterBorder")
$ImgTitleIcon       = $window.FindName("ImgTitleIcon")
$TxtWindowTitle     = $window.FindName("TxtWindowTitle")
$TxtWindowSubtitle  = $window.FindName("TxtWindowSubtitle")
$TxtBrandBadge      = $window.FindName("TxtBrandBadge")
$BtnTitleTray       = $window.FindName("BtnTitleTray")
$BtnTitleMin        = $window.FindName("BtnTitleMin")
$BtnTitleMax        = $window.FindName("BtnTitleMax")
$PathMaxIcon        = $window.FindName("PathMaxIcon")
$BtnTitleClose      = $window.FindName("BtnTitleClose")
$DotAccount         = $window.FindName("DotAccount")
$TxtAccountStatus   = $window.FindName("TxtAccountStatus")
$CmbAccountProfile  = $window.FindName("CmbAccountProfile")
$TxtSettingsSecAccounts = $window.FindName("TxtSettingsSecAccounts")
$TxtSettingsSecGeneral  = $window.FindName("TxtSettingsSecGeneral")
$LblLanguage        = $window.FindName("LblLanguage")
$ChkCloudIsland     = $window.FindName("ChkCloudIsland")
$TxtSettingsSecBackup   = $window.FindName("TxtSettingsSecBackup")
$TxtSettingsSecSync     = $window.FindName("TxtSettingsSecSync")
$BtnAddAccount      = $window.FindName("BtnAddAccount")
$BtnNavFolders      = $window.FindName("BtnNavFolders")
$IndNavFolders      = $window.FindName("IndNavFolders")
$TxtNavFolders      = $window.FindName("TxtNavFolders")
$BtnNavActivity     = $window.FindName("BtnNavActivity")
$IndNavActivity     = $window.FindName("IndNavActivity")
$TxtNavActivity     = $window.FindName("TxtNavActivity")
$DotNavActivityLive = $window.FindName("DotNavActivityLive")
$BtnNavStorage      = $window.FindName("BtnNavStorage")
$IndNavStorage      = $window.FindName("IndNavStorage")
$TxtNavStorage      = $window.FindName("TxtNavStorage")
$BtnNavSettings     = $window.FindName("BtnNavSettings")
$IndNavSettings     = $window.FindName("IndNavSettings")
$TxtNavSettings     = $window.FindName("TxtNavSettings")
$TxtSidebarAccountsTitle = $window.FindName("TxtSidebarAccountsTitle")
$TxtSidebarAccountsCount = $window.FindName("TxtSidebarAccountsCount")
$ListSidebarAccounts     = $window.FindName("ListSidebarAccounts")
$DotMount           = $window.FindName("DotMount")
$TxtMountStatus     = $window.FindName("TxtMountStatus")
$CmbDriveLetter     = $window.FindName("CmbDriveLetter")
$CmbMountMode       = $window.FindName("CmbMountMode")
$CbiMountStream     = $window.FindName("CbiMountStream")
$CbiMountMirror     = $window.FindName("CbiMountMirror")
$CbiMountUnified    = $window.FindName("CbiMountUnified")
$CbiMountHidden     = $window.FindName("CbiMountHidden")
$CmbMountScope      = $window.FindName("CmbMountScope")
$CbiScopeMyDrive    = $window.FindName("CbiScopeMyDrive")
$CbiScopeMyComputer = $window.FindName("CbiScopeMyComputer")
$CbiScopeBoth       = $window.FindName("CbiScopeBoth")
$BtnMount           = $window.FindName("BtnMount")
$TxtSideQuotaLabel  = $window.FindName("TxtSideQuotaLabel")
$BarSideQuota       = $window.FindName("BarSideQuota")
$CmbLanguage        = $window.FindName("CmbLanguage")
$ChkStartup         = $window.FindName("ChkStartup")
$ChkFolderBadges    = $window.FindName("ChkFolderBadges")
$ChkExplorerMenu    = $window.FindName("ChkExplorerMenu")
$ChkAutoWatchSync   = $window.FindName("ChkAutoWatchSync")
$TxtAutoWatchStatus = $window.FindName("TxtAutoWatchStatus")
$PanelFolders       = $window.FindName("PanelFolders")
$PanelActivity      = $window.FindName("PanelActivity")
$PanelStorage       = $window.FindName("PanelStorage")
$PanelSettings      = $window.FindName("PanelSettings")
$TxtFoldersHeader   = $window.FindName("TxtFoldersHeader")
$LblFoldersSubHint  = $window.FindName("LblFoldersSubHint")
$BtnAddFolder       = $window.FindName("BtnAddFolder")
$GridFolders        = $window.FindName("GridFolders")
$CtxMenuFolders     = $window.FindName("CtxMenuFolders")
$CtxSyncFolder      = $window.FindName("CtxSyncFolder")
$CtxDryRunFolder    = $window.FindName("CtxDryRunFolder")
$CtxRestoreFolder   = $window.FindName("CtxRestoreFolder")
$CtxSwitchTarget    = $window.FindName("CtxSwitchTarget")
$CtxOpenLocal       = $window.FindName("CtxOpenLocal")
$CtxRemoveFolder    = $window.FindName("CtxRemoveFolder")
$BtnSyncSelected    = $window.FindName("BtnSyncSelected")
$BtnToggleTarget    = $window.FindName("BtnToggleTarget")
$BtnRemoveFolder    = $window.FindName("BtnRemoveFolder")
$TxtQuickPolicyChip = $window.FindName("TxtQuickPolicyChip")
$LblFeedHeader      = $window.FindName("LblFeedHeader")
$BtnClearLog        = $window.FindName("BtnClearLog")
$GridBottomSplit    = $window.FindName("GridBottomSplit")
$CardFeed           = $window.FindName("CardFeed")
$CardLog            = $window.FindName("CardLog")
$GridActivity       = $window.FindName("GridActivity")
$LblLogHeader       = $window.FindName("LblLogHeader")
$TxtLog             = $window.FindName("TxtLog")
$TxtQuotaHeader     = $window.FindName("TxtQuotaHeader")
$BarDriveQuota      = $window.FindName("BarDriveQuota")
$GridQuotaMetrics   = $window.FindName("GridQuotaMetrics")
$TxtQuotaTotal      = $window.FindName("TxtQuotaTotal")
$TxtQuotaUsed       = $window.FindName("TxtQuotaUsed")
$TxtQuotaFree       = $window.FindName("TxtQuotaFree")
$TxtQuotaTrash      = $window.FindName("TxtQuotaTrash")
$BtnRefreshQuota    = $window.FindName("BtnRefreshQuota")
$BtnCleanArchive    = $window.FindName("BtnCleanArchive")
$BtnOpenDriveWeb    = $window.FindName("BtnOpenDriveWeb")
$BtnEmptyDriveTrash = $window.FindName("BtnEmptyDriveTrash")
$TxtMultiDriveTitle = $window.FindName("TxtMultiDriveTitle")
$TxtMultiDriveDesc  = $window.FindName("TxtMultiDriveDesc")
$LblDriveLayout     = $window.FindName("LblDriveLayout")
$CmbDriveLayout     = $window.FindName("CmbDriveLayout")
$CbiLayoutSeparate  = $window.FindName("CbiLayoutSeparate")
$CbiLayoutUnified   = $window.FindName("CbiLayoutUnified")
$LblDriveLayoutSet  = $window.FindName("LblDriveLayoutSet")
$CmbDriveLayoutSettings = $window.FindName("CmbDriveLayoutSettings")
$CbiLayoutSetSeparate   = $window.FindName("CbiLayoutSetSeparate")
$CbiLayoutSetUnified    = $window.FindName("CbiLayoutSetUnified")
$GridMultiDrives    = $window.FindName("GridMultiDrives")
$CtxMenuDrives      = $window.FindName("CtxMenuDrives")
$CtxDriveToggle     = $window.FindName("CtxDriveToggle")
$CtxDriveUnified    = $window.FindName("CtxDriveUnified")
$CtxDriveSeparate   = $window.FindName("CtxDriveSeparate")
$CtxDriveHide       = $window.FindName("CtxDriveHide")
$CtxDriveRename     = $window.FindName("CtxDriveRename")
$BtnMountAll        = $window.FindName("BtnMountAll")
$BtnUnmountAll      = $window.FindName("BtnUnmountAll")
$BtnToggleDriveRow  = $window.FindName("BtnToggleDriveRow")
$BtnRenameAccount   = $window.FindName("BtnRenameAccount")
$BtnCloudTransfer   = $window.FindName("BtnCloudTransfer")
$BtnCloudTransferSet= $window.FindName("BtnCloudTransferSet")
$BtnUpdateBanner    = $window.FindName("BtnUpdateBanner")
$TxtUpdateBanner    = $window.FindName("TxtUpdateBanner")
$TxtUpdateStatus    = $window.FindName("TxtUpdateStatus")
$BtnCheckUpdates    = $window.FindName("BtnCheckUpdates")
$BtnSetTabAccounts  = $window.FindName("BtnSetTabAccounts")
$BtnSetTabSync      = $window.FindName("BtnSetTabSync")
$BtnSetTabBackup    = $window.FindName("BtnSetTabBackup")
$BtnSetTabGeneral   = $window.FindName("BtnSetTabGeneral")
$BtnSetTabNotif     = $window.FindName("BtnSetTabNotif")
$CardSetAccounts    = $window.FindName("CardSetAccounts")
$ListSettingsAccounts     = $window.FindName("ListSettingsAccounts")
$TxtSettingsAccountsCount = $window.FindName("TxtSettingsAccountsCount")
$TxtAccountsListHint      = $window.FindName("TxtAccountsListHint")
$CardSetSync        = $window.FindName("CardSetSync")
$CardSetBackup      = $window.FindName("CardSetBackup")
$CardSetGeneral     = $window.FindName("CardSetGeneral")
$CardSetNotif       = $window.FindName("CardSetNotif")
$TxtSettingsPageTitle        = $window.FindName("TxtSettingsPageTitle")
$TxtSettingsSecNotifications = $window.FindName("TxtSettingsSecNotifications")
$ChkNotifMaster              = $window.FindName("ChkNotifMaster")
$PnlNotifSub                 = $window.FindName("PnlNotifSub")
$ChkNotifManual              = $window.FindName("ChkNotifManual")
$ChkNotifAutoSync            = $window.FindName("ChkNotifAutoSync")
$ChkNotifErrors              = $window.FindName("ChkNotifErrors")
$ChkNotifDriveEvents         = $window.FindName("ChkNotifDriveEvents")
$LblSchedule                 = $window.FindName("LblSchedule")
$TxtScheduleStatus  = $window.FindName("TxtScheduleStatus")
$BtnOpenScheduler   = $window.FindName("BtnOpenScheduler")
$BtnDisableSchedule = $window.FindName("BtnDisableSchedule")
$ChkJsonRules       = $window.FindName("ChkJsonRules")
$CmbJsonPreset      = $window.FindName("CmbJsonPreset")
$CbiPresetDev       = $window.FindName("CbiPresetDev")
$CbiPresetCreative  = $window.FindName("CbiPresetCreative")
$CbiPresetGeneral   = $window.FindName("CbiPresetGeneral")
$CbiPresetCustom    = $window.FindName("CbiPresetCustom")
$BtnEditJsonRules   = $window.FindName("BtnEditJsonRules")
$BtnLoadJsonRules   = $window.FindName("BtnLoadJsonRules")
$BtnPickExclusions  = $window.FindName("BtnPickExclusions")
$PillSavedSpace     = $window.FindName("PillSavedSpace")
$TxtSavedSpace      = $window.FindName("TxtSavedSpace")
$TxtRulesSummary    = $window.FindName("TxtRulesSummary")
$LblDeletePolicy    = $window.FindName("LblDeletePolicy")
$CmbDeletePolicy    = $window.FindName("CmbDeletePolicy")
$CbiPolicySafe      = $window.FindName("CbiPolicySafe")
$CbiPolicyCopy      = $window.FindName("CbiPolicyCopy")
$CbiPolicyMirror    = $window.FindName("CbiPolicyMirror")
$LblDefaultTarget   = $window.FindName("LblDefaultTarget")
$CmbDefaultTarget   = $window.FindName("CmbDefaultTarget")
$CbiDefTargetDrive  = $window.FindName("CbiDefTargetDrive")
$CbiDefTargetComp   = $window.FindName("CbiDefTargetComp")
$LblMyComputer      = $window.FindName("LblMyComputer")
$TxtComputerLabel   = $window.FindName("TxtComputerLabel")
$TxtDeletePolicyHint= $window.FindName("TxtDeletePolicyHint")
$LblSpeedMode       = $window.FindName("LblSpeedMode")
$CmbSpeedPreset     = $window.FindName("CmbSpeedPreset")
$CbiSpeedTurbo      = $window.FindName("CbiSpeedTurbo")
$CbiSpeedBalanced   = $window.FindName("CbiSpeedBalanced")
$CbiSpeedEco        = $window.FindName("CbiSpeedEco")
$LblMaxDelete       = $window.FindName("LblMaxDelete")
$CmbMaxDelete       = $window.FindName("CmbMaxDelete")
$CbiMaxDelUnlimited = $window.FindName("CbiMaxDelUnlimited")
$CbiMaxDel200       = $window.FindName("CbiMaxDel200")
$CbiMaxDel500       = $window.FindName("CbiMaxDel500")
$CbiMaxDel1000      = $window.FindName("CbiMaxDel1000")
$CbiMaxDel5000      = $window.FindName("CbiMaxDel5000")
$BtnCustomClientId  = $window.FindName("BtnCustomClientId")
$BtnSyncToggle      = $window.FindName("BtnSyncToggle")
$TxtSyncToggle      = $window.FindName("TxtSyncToggle")
$BtnDryRun          = $window.FindName("BtnDryRun")
$TxtDryRun          = $window.FindName("TxtDryRun")
$BtnRestore         = $window.FindName("BtnRestore")
$TxtRestore         = $window.FindName("TxtRestore")
$BarSyncProgress    = $window.FindName("BarSyncProgress")
$TxtProgressPct     = $window.FindName("TxtProgressPct")
$TxtUploadCounters  = $window.FindName("TxtUploadCounters")
$TxtLiveTransfer    = $window.FindName("TxtLiveTransfer")

if ($null -ne $script:AppLogoPngSource) { $ImgTitleIcon.Source = $script:AppLogoPngSource }
