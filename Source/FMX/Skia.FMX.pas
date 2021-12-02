{************************************************************************}
{                                                                        }
{                              Skia4Delphi                               }
{                                                                        }
{ Copyright (c) 2011-2021 Google LLC.                                    }
{ Copyright (c) 2021 Skia4Delphi Project.                                }
{                                                                        }
{ Use of this source code is governed by a BSD-style license that can be }
{ found in the LICENSE file.                                             }
{                                                                        }
{************************************************************************}
unit Skia.FMX;

interface

{$SCOPEDENUMS ON}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Ani,

  { Skia }
  Skia;

const
  {$IF CompilerVersion < 34}
  SkSupportedPlatformsMask = pidWin32 or pidWin64;
  {$ELSEIF CompilerVersion < 35}
  SkSupportedPlatformsMask = pidWin32 or pidWin64 or pidLinux64 or pidAndroid32Arm or pidAndroid64Arm or pidiOSDevice64 or pidOSX64;
  {$ELSE}
  SkSupportedPlatformsMask = pidWin32 or pidWin64 or pidLinux64 or pidAndroidArm32 or pidAndroidArm64 or pidiOSDevice64 or pidOSX64 or pidOSXArm64;
  {$ENDIF}

type
  ESkFMX = class(SkException);
  TSkDrawProc = reference to procedure(const ACanvas: ISkCanvas);

  { TSkBitmapHelper }

  TSkBitmapHelper = class helper for TBitmap
  public
    procedure SkiaDraw(const AProc: TSkDrawProc; const AStartClean: Boolean = True);
    function ToSkImage: ISkImage;
  end;

  TSkDrawEvent = procedure(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single) of object;

  { TSkCustomControl }

  TSkCustomControl = class abstract(TControl)
  strict private
    FBuffer: TBitmap;
    FDrawCached: Boolean;
    FDrawCacheEnabled: Boolean;
    FOnDraw: TSkDrawEvent;
    procedure SetDrawCacheEnabled(const AValue: Boolean);
    procedure SetOnDraw(const AValue: TSkDrawEvent);
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual;
    procedure DrawDesignBorder(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
    function NeedsRedraw: Boolean; virtual;
    procedure Paint; override; final;
    property DrawCacheEnabled: Boolean read FDrawCacheEnabled write SetDrawCacheEnabled default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Redraw;
  published
    property Align;
    property Anchors;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property Enabled default True;
    property EnableDragHighlight default True;
    property Height;
    property Hint;
    property HitTest default False;
    property Locked default False;
    property Margins;
    property Opacity;
    property Padding;
    {$IF CompilerVersion >= 30}
    property ParentShowHint;
    {$ENDIF}
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowHint;
    {$IF CompilerVersion >= 28}
    property Size;
    {$ENDIF}
    property Visible default True;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragEnd;
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDraw: TSkDrawEvent read FOnDraw write SetOnDraw;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnPainting;
    property OnResize;
    {$IF CompilerVersion >= 32}
    property OnResized;
    {$ENDIF}
  end;

  { TSkPaintBox }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkPaintBox = class(TSkCustomControl);

  TSkSvgSource = type string;

  { TSkSvgBrush }

  TSkSvgBrush = class(TPersistent)
  strict private
    FDOM: ISkSVGDOM;
    FOnChanged: TNotifyEvent;
    FOverrideColor: TAlphaColor;
    FSource: TSkSvgSource;
    function IsOverrideColorStored: Boolean;
    procedure SetOverrideColor(const AValue: TAlphaColor);
    procedure SetSource(const AValue: TSkSvgSource);
  strict protected
    procedure DoChanged; virtual;
  public
    procedure Assign(ASource: TPersistent); override;
    procedure Render(const ACanvas: ISkCanvas; const ADestRect: TRectF; const AOpacity: Single);
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    property OverrideColor: TAlphaColor read FOverrideColor write SetOverrideColor stored IsOverrideColorStored;
    property Source: TSkSvgSource read FSource write SetSource;
  end;

  { TSkSvg }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkSvg = class(TSkCustomControl)
  strict private
    FSvg: TSkSvgBrush;
    procedure SetSvg(const AValue: TSkSvgBrush);
    procedure SvgChanged(ASender: TObject);
  strict protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Svg: TSkSvgBrush read FSvg write SetSvg;
  end;

  { TSkCustomAnimatedControl }

  TSkCustomAnimatedControl = class abstract(TSkCustomControl)
  strict private
    FAbsoluteVisible: Boolean;
    FAbsoluteVisibleCached: Boolean;
    FAnimation: TAnimation;
    FAnimationStartTickCount: Cardinal;
    FFixedProgress: Boolean;
    FLoop: Boolean;
    FOnAnimationFinished: TNotifyEvent;
    FOnAnimationProgress: TNotifyEvent;
    FOnAnimationStart: TNotifyEvent;
    FProgress: Double;
    FProgressChangedManually: Boolean;
    FSuccessRepaint: Boolean;
    function GetAbsoluteVisible: Boolean;
    function GetRunningAnimation: Boolean;
    procedure SetFixedProgress(const AValue: Boolean);
    procedure SetLoop(const AValue: Boolean);
    procedure SetProgress(AValue: Double);
  private
    procedure ProcessAnimation;
  strict protected
    procedure AncestorVisibleChanged(const AVisible: Boolean); override;
    function CanRunAnimation: Boolean; virtual;
    procedure CheckAnimation;
    procedure DoAnimationFinished; virtual;
    procedure DoAnimationProgress; virtual;
    procedure DoAnimationStart; virtual;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    function GetDuration: Double; virtual; abstract;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single); virtual; abstract;
    property AbsoluteVisible: Boolean read GetAbsoluteVisible;
    property Duration: Double read GetDuration;
    property FixedProgress: Boolean read FFixedProgress write SetFixedProgress;
    property Progress: Double read FProgress write SetProgress;
    property Loop: Boolean read FLoop write SetLoop;
    property OnAnimationFinished: TNotifyEvent read FOnAnimationFinished write FOnAnimationFinished;
    property OnAnimationProgress: TNotifyEvent read FOnAnimationProgress write FOnAnimationProgress;
    property OnAnimationStart: TNotifyEvent read FOnAnimationStart write FOnAnimationStart;
    property RunningAnimation: Boolean read GetRunningAnimation;
  public
    constructor Create(AOwner: TComponent); override;
    procedure RecalcEnabled; override;
    procedure SetNewScene(AScene: IScene); override;
  end;

  TSkLottieSource = type string;
  TSkLottieFormat = (Json, Tgs);

  { TSkLottieAnimation }

  [ComponentPlatforms(SkSupportedPlatformsMask)]
  TSkLottieAnimation = class(TSkCustomAnimatedControl)
  strict private
    FSkottie: ISkottieAnimation;
    FSource: TSkLottieSource;
    procedure ReadTgs(AStream: TStream);
    procedure SetSource(const AValue: TSkLottieSource);
    procedure WriteTgs(AStream: TStream);
  strict protected
    function CanRunAnimation: Boolean; override;
    procedure DefineProperties(AFiler: TFiler); override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    function GetDuration: Double; override;
    procedure RenderFrame(const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double; const AOpacity: Single); override;
  public
    property FixedProgress;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure SaveToStream(const AStream: TStream; const AFormat: TSkLottieFormat = TSkLottieFormat.Json);
    property Progress;
    property RunningAnimation;
    property Skottie: ISkottieAnimation read FSkottie;
  published
    property Loop default True;
    property Source: TSkLottieSource read FSource write SetSource stored False;
    property OnAnimationFinished;
    property OnAnimationProgress;
    property OnAnimationStart;
  end;

implementation

uses
  { Delphi }
  System.Math,
  System.Math.Vectors,
  System.ZLib,
  FMX.Forms;

{ TSkBitmapHelper }

procedure TSkBitmapHelper.SkiaDraw(const AProc: TSkDrawProc; const AStartClean: Boolean);
var
  LColorType: TSkColorType;
  LImageInfo: TSkImageInfo;
  LSurface: ISkSurface;
  LData: TBitmapData;
begin
  if IsEmpty then
    raise ESkFMX.Create('Invalid bitmap');
  case PixelFormat of
    TPixelFormat.RGBA: LColorType := TSkColorType.RGBA8888;
    TPixelFormat.BGRA: LColorType := TSkColorType.BGRA8888;
  else
    raise ESkFMX.Create('Invalid pixelformat');
  end;
  LImageInfo := TSkImageInfo.Create(Width, Height, LColorType);
  if Map(TMapAccess.ReadWrite, LData) then
    try
      LSurface := TSkSurface.MakeRasterDirect(LImageInfo, LData.Data, LData.Pitch);
      if AStartClean then
        LSurface.Canvas.Clear(TAlphaColors.Null);
      AProc(LSurface.Canvas);
    finally
      Unmap(LData);
    end;
end;

function TSkBitmapHelper.ToSkImage: ISkImage;
var
  LColorType: TSkColorType;
  LData: TBitmapData;
begin
  if IsEmpty then
    raise ESkFMX.Create('Invalid bitmap');
  case PixelFormat of
    TPixelFormat.RGBA: LColorType := TSkColorType.RGBA8888;
    TPixelFormat.BGRA: LColorType := TSkColorType.BGRA8888;
  else
    raise ESkFMX.Create('Invalid pixelformat');
  end;
  if not Map(TMapAccess.Read, LData) then
    raise ESkFMX.Create('Could not map the bitmap');
  try
    Result := TSkImage.MakeRaster(TSkImageInfo.Create(Width, Height, LColorType), LData.Data, LData.Pitch);
  finally
    Unmap(LData);
  end;
end;

{ TSkCustomControl }

constructor TSkCustomControl.Create(AOwner: TComponent);
begin
  inherited;
  FDrawCacheEnabled := True;
  HitTest := False;
end;

destructor TSkCustomControl.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited;
end;

procedure TSkCustomControl.Draw(const ACanvas: ISkCanvas; const ADest: TRectF;
  const AOpacity: Single);
begin
  if csDesigning in ComponentState then
    DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

procedure TSkCustomControl.DrawDesignBorder(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
const
  DesignBorderColor = $A0909090;
var
  R: TRectF;
  LPaint: ISkPaint;
begin
  R := ADest;
  InflateRect(R, -0.5, -0.5);
  ACanvas.Save;
  try
    LPaint := TSkPaint.Create;
    LPaint.AlphaF := AOpacity;
    LPaint.Color := DesignBorderColor;
    LPaint.Style := TSkPaintStyle.Stroke;
    LPaint.PathEffect := TSKPathEffect.MakeDash(TArray<Single>.Create(3, 1), 0);
    LPaint.StrokeWidth := 1;
    ACanvas.DrawRect(R, LPaint);
  finally
    ACanvas.Restore;
  end;
end;

function TSkCustomControl.NeedsRedraw: Boolean;
begin
  Result := (not FDrawCached) or (not FDrawCacheEnabled) or (FBuffer = nil);
end;

procedure TSkCustomControl.Paint;

  function AlignToPixel(const ARect: TRectF): TRectF;
  begin
    {$IF CompilerVersion >= 31}
    Result := Canvas.AlignToPixel(ARect);
    {$ELSE}
    Result.Left := Canvas.AlignToPixelHorizontally(ARect.Left);
    Result.Top := Canvas.AlignToPixelVertically(ARect.Top);
    Result.Right := Result.Left + Round(ARect.Width * Canvas.Scale) / Canvas.Scale; // keep ratio horizontally
    Result.Bottom := Result.Top + Round(ARect.Height * Canvas.Scale) / Canvas.Scale; // keep ratio vertically
    {$ENDIF}
  end;

var
  LSceneScale: Single;
  LAbsoluteSize: TSize;
begin
  if Assigned(Scene) then
    LSceneScale := Scene.GetSceneScale
  else
    LSceneScale := 1;
  LAbsoluteSize := TSize.Create(Round(AbsoluteWidth * LSceneScale), Round(AbsoluteHeight * LSceneScale));
  if NeedsRedraw or (TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteSize) then
  begin
    if FBuffer = nil then
      FBuffer := TBitmap.Create(LAbsoluteSize.Width, LAbsoluteSize.Height)
    else if TSize.Create(FBuffer.Width, FBuffer.Height) <> LAbsoluteSize then
      FBuffer.SetSize(LAbsoluteSize.Width, LAbsoluteSize.Height);
    FBuffer.SkiaDraw(
      procedure(const ACanvas: ISkCanvas)
      var
        LAbsoluteScale: TPointF;
        LDestRect: TRectF;
      begin
        ACanvas.Clear(TAlphaColors.Null);
        LAbsoluteScale := AbsoluteScale * LSceneScale;
        ACanvas.Concat(TMatrix.CreateScaling(LAbsoluteScale.X, LAbsoluteScale.Y));
        LDestRect := TRectF.Create(PointF(0, 0), LAbsoluteSize.Width / LAbsoluteScale.X, LAbsoluteSize.Height / LAbsoluteScale.Y);
        Draw(ACanvas, LDestRect, 1);
        if Assigned(FOnDraw) then
          FOnDraw(Self, ACanvas, LDestRect, 1);
      end, False);
    FDrawCached := True;
  end;
  Canvas.DrawBitmap(FBuffer, RectF(0, 0, FBuffer.Width, FBuffer.Height), AlignToPixel(LocalRect), AbsoluteOpacity);
end;

procedure TSkCustomControl.Redraw;
begin
  FDrawCached := False;
  Repaint;
end;

procedure TSkCustomControl.SetDrawCacheEnabled(const AValue: Boolean);
begin
  if FDrawCacheEnabled <> AValue then
  begin
    FDrawCacheEnabled := AValue;
    if not AValue then
      Repaint;
  end;
end;

procedure TSkCustomControl.SetOnDraw(const AValue: TSkDrawEvent);
begin
  if TMethod(FOnDraw) <> TMethod(AValue) then
  begin
    FOnDraw := AValue;
    Redraw;
  end;
end;

{ TSkSvgBrush }

procedure TSkSvgBrush.Assign(ASource: TPersistent);
begin
  if ASource is TSkSvgBrush then
  begin
    FOverrideColor := TSkSvgBrush(ASource).FOverrideColor;
    FSource := TSkSvgBrush(ASource).FSource;
    FDOM := TSkSvgBrush(ASource).FDOM;
    DoChanged;
  end
  else
    inherited;
end;

procedure TSkSvgBrush.DoChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

function TSkSvgBrush.IsOverrideColorStored: Boolean;
begin
  Result := FOverrideColor <> Default(TAlphaColor);
end;

procedure TSkSvgBrush.Render(const ACanvas: ISkCanvas; const ADestRect: TRectF;
  const AOpacity: Single);

  function PlaceIntoTopLeft(const ASourceRect, ADesignatedArea: TRectF): TRectF;
  begin
    Result := ASourceRect;
    if (ASourceRect.Width > ADesignatedArea.Width) or (ASourceRect.Height > ADesignatedArea.Height) then
      Result := Result.FitInto(ADesignatedArea);
    Result.SetLocation(ADesignatedArea.TopLeft);
  end;

  procedure DrawOverrideColor(const ACanvas: ISkCanvas; const ADOM: ISkSVGDOM;
    const ASvgRect, ADestRect, AWrappedDest: TRectF);
  var
    LSurface: ISkSurface;
    LImage: ISkImage;
    LPaint: ISkPaint;
  begin
    LSurface := TSkSurface.MakeRaster(Round(AWrappedDest.Width), Round(AWrappedDest.Height));
    LSurface.Canvas.Clear(TAlphaColors.Null);
    LSurface.Canvas.Scale(AWrappedDest.Width / ASvgRect.Width, AWrappedDest.Height / ASvgRect.Height);
    FDOM.Render(LSurface.Canvas);
    LImage := LSurface.MakeImageSnapshot;
    LPaint := TSkPaint.Create;
    if FOverrideColor <> TAlphaColors.Null then
      LPaint.ColorFilter := TSkColorFilter.MakeBlend(FOverrideColor, TSkBlendMode.SrcIn);
    LPaint.Style := TSkPaintStyle.Fill;
    ACanvas.DrawImage(LImage, AWrappedDest.Left, AWrappedDest.Top, LPaint);
  end;

var
  LStream: TStringStream;
  LSvgRect: TRectF;
  LWrappedDest: TRectF;
begin
  if (FSource <> '') and not ADestRect.IsEmpty then
  begin
    if not Assigned(FDOM) then
    begin
      LStream := TStringStream.Create(FSource);
      try
        FDOM := TSkSVGDOM.Make(LStream);
      finally
        LStream.Free;
      end;
    end;
    if not Assigned(FDOM) then
      Exit;
    if FDOM.ContainerSize.IsZero then
      FDOM.ContainerSize := ADestRect.Size;
    LSvgRect := TRectF.Create(PointF(0, 0), FDOM.ContainerSize);
    if LSvgRect.IsEmpty then
      Exit;
    LWrappedDest := LSvgRect.FitInto(ADestRect);
    if FOverrideColor <> TAlphaColors.Null then
      DrawOverrideColor(ACanvas, FDOM, LSvgRect, ADestRect, LWrappedDest)
    else
    begin
      ACanvas.Translate(LWrappedDest.Left, LWrappedDest.Top);
      ACanvas.Scale(LWrappedDest.Width / LSvgRect.Width, LWrappedDest.Height / LSvgRect.Height);
      FDOM.Render(ACanvas);
    end;
  end;
end;

procedure TSkSvgBrush.SetOverrideColor(const AValue: TAlphaColor);
begin
  if FOverrideColor <> AValue then
  begin
    FOverrideColor := AValue;
    if FSource <> '' then
      DoChanged;
  end;
end;

procedure TSkSvgBrush.SetSource(const AValue: TSkSvgSource);
begin
  if FSource <> AValue then
  begin
    FSource := AValue;
    FDOM := nil;
    DoChanged;
  end;
end;

{ TSkSvg }

constructor TSkSvg.Create(AOwner: TComponent);
begin
  inherited;
  FSvg := TSkSvgBrush.Create;
  FSvg.OnChanged := SvgChanged;
end;

destructor TSkSvg.Destroy;
begin
  FSvg.Free;
  inherited;
end;

procedure TSkSvg.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  inherited;
  FSvg.Render(ACanvas, ADest, AOpacity);
end;

procedure TSkSvg.SetSvg(const AValue: TSkSvgBrush);
begin
  FSvg.Assign(AValue);
end;

procedure TSkSvg.SvgChanged(ASender: TObject);
begin
  Redraw;
end;

type
  { TRepaintAnimation }

  TRepaintAnimation = class(TAnimation)
  protected
    procedure ProcessAnimation; override;
  end;

{ TRepaintAnimation }

procedure TRepaintAnimation.ProcessAnimation;
begin
  TSkCustomAnimatedControl(Parent).ProcessAnimation;
end;

{ TSkCustomAnimatedControl }

procedure TSkCustomAnimatedControl.AncestorVisibleChanged(const AVisible: Boolean);
var
  LLastAbsoluteVisible: Boolean;
begin
  LLastAbsoluteVisible := FAbsoluteVisible;
  if not AVisible then
  begin
    FAbsoluteVisible := False;
    FAbsoluteVisibleCached := True;
  end
  else
    FAbsoluteVisibleCached := False;
  if (not FFixedProgress) and (not FProgressChangedManually) and (not LLastAbsoluteVisible) and AbsoluteVisible then
  begin
    FProgress := 0;
    FAnimationStartTickCount := TThread.GetTickCount;
  end;
  CheckAnimation;
  inherited;
end;

function TSkCustomAnimatedControl.CanRunAnimation: Boolean;
begin
  Result := Assigned(Scene) and (not FFixedProgress) and
    ([csDestroying, csDesigning] * ComponentState = []) and
    AbsoluteVisible and AbsoluteEnabled and
    (AbsoluteWidth > 0) and (AbsoluteHeight > 0) and
    (FLoop or not SameValue(FProgress, 1, TEpsilon.Matrix)) and
    (Scene.GetObject is TCommonCustomForm) and TCommonCustomForm(Scene.GetObject).Visible;
end;

procedure TSkCustomAnimatedControl.CheckAnimation;

  procedure FixStartTickCount;
  var
    LNewTickCount: Int64;
  begin
    LNewTickCount := TThread.GetTickCount - Round(FProgress * Duration * 1000);
    if LNewTickCount < 0 then
      LNewTickCount := High(Cardinal) + LNewTickCount;
    FAnimationStartTickCount := Cardinal(LNewTickCount);
  end;

var
  LCanRunAnimation: Boolean;
begin
  if Assigned(FAnimation) then
  begin
    LCanRunAnimation := CanRunAnimation;
    if FAnimation.Enabled <> LCanRunAnimation then
    begin
      FAnimation.Enabled := LCanRunAnimation;
      if LCanRunAnimation then
      begin
        FixStartTickCount;
        DoAnimationStart;
      end
      else
        DoAnimationFinished;
    end;
  end;
end;

constructor TSkCustomAnimatedControl.Create(AOwner: TComponent);
begin
  inherited;
  if csDesigning in ComponentState then
  begin
    FProgress := 0.5;
    FFixedProgress := True;
  end;
  FLoop := True;
  FAnimation := TRepaintAnimation.Create(Self);
  FAnimation.Stored := False;
  FAnimation.Loop := True;
  FAnimation.Duration := 30;
  FAnimation.Parent := Self;
  FAbsoluteVisible := Visible;
  FAbsoluteVisibleCached := True;
  DrawCacheEnabled := False;
end;

procedure TSkCustomAnimatedControl.DoAnimationFinished;
begin
  if Assigned(FOnAnimationFinished) then
    FOnAnimationFinished(Self);
  FProgressChangedManually := False;
end;

procedure TSkCustomAnimatedControl.DoAnimationProgress;
begin
  if Assigned(FOnAnimationProgress) then
    FOnAnimationProgress(Self);
end;

procedure TSkCustomAnimatedControl.DoAnimationStart;
begin
  if Assigned(FOnAnimationStart) then
    FOnAnimationStart(Self);
end;

procedure TSkCustomAnimatedControl.Draw(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AOpacity: Single);

  procedure FixElapsedSeconds(const ACurrentTickCount: Cardinal;
    var AStartTickCount: Cardinal; var AElapsedSeconds: Double);
  var
    LMillisecondsElapsed: Int64;
  begin
    Assert(ACurrentTickCount < AStartTickCount);
    if ACurrentTickCount >= Cardinal(Ceil(Duration * 1000)) then
    begin
      if FLoop then
      begin
        LMillisecondsElapsed := ACurrentTickCount + High(Cardinal) - AStartTickCount;
        LMillisecondsElapsed := LMillisecondsElapsed mod Round(Duration * 1000);
        Assert(ACurrentTickCount > LMillisecondsElapsed);
        FAnimationStartTickCount := Cardinal(ACurrentTickCount - LMillisecondsElapsed);
      end
      else
        AStartTickCount := ACurrentTickCount - Cardinal(Ceil(Duration * 1000));
      AElapsedSeconds := (ACurrentTickCount - AStartTickCount) / 1000;
    end
    else
    begin
      LMillisecondsElapsed := ACurrentTickCount + High(Cardinal) - AStartTickCount;
      AElapsedSeconds := LMillisecondsElapsed / 1000;
    end;
    Assert(AElapsedSeconds >= 0);
  end;

  function CalcProgress: Double;
  var
    LElapsedSeconds: Double;
    LCurrentTickCount: Cardinal;
  begin
    if Enabled then
    begin
      LCurrentTickCount := TThread.GetTickCount;
      LElapsedSeconds := (LCurrentTickCount - FAnimationStartTickCount) / 1000;
      if LElapsedSeconds < 0 then
        FixElapsedSeconds(LCurrentTickCount, FAnimationStartTickCount, LElapsedSeconds);
      if FLoop then
      begin
        {$IF CompilerVersion >= 29} // Delphi XE8
        LElapsedSeconds := FMod(LElapsedSeconds, Duration);
        {$ELSE}
        LElapsedSeconds := (Round(LElapsedSeconds * 1000) mod Round(Duration * 1000)) / 1000;
        {$ENDIF}
      end
      else
        LElapsedSeconds := Min(LElapsedSeconds, Duration);
      if SameValue(Duration, 0, TEpsilon.Matrix) then
        Result := 1
      else
        Result := LElapsedSeconds / Duration;
    end
    else
      Result := FProgress;
  end;

var
  LProgress: Double;
begin
  inherited;
  if Assigned(FAnimation) and not FAnimation.Enabled then
    CheckAnimation;
  if FFixedProgress then
    LProgress := FProgress
  else
    LProgress := CalcProgress;
  RenderFrame(ACanvas, ADest, LProgress, AOpacity);
  if not SameValue(LProgress, FProgress, TEpsilon.Matrix) then
  begin
    FProgress := LProgress;
    DoAnimationProgress;
  end;
  if (not FLoop) and SameValue(LProgress, 1, TEpsilon.Matrix) then
  begin
    FProgress := 1;
    CheckAnimation;
  end;
  FSuccessRepaint := True;
end;

function TSkCustomAnimatedControl.GetAbsoluteVisible: Boolean;
begin
  if not FAbsoluteVisibleCached then
  begin
    FAbsoluteVisible := GetParentedVisible;
    FAbsoluteVisibleCached := True;
  end;
  Result := FAbsoluteVisible;
end;

function TSkCustomAnimatedControl.GetRunningAnimation: Boolean;
begin
  Result := Assigned(FAnimation) and FAnimation.Enabled;
end;

procedure TSkCustomAnimatedControl.ProcessAnimation;
begin
  if not FSuccessRepaint then
    CheckAnimation;
  FSuccessRepaint := False;
  Repaint;
end;

procedure TSkCustomAnimatedControl.RecalcEnabled;
begin
  inherited;
  CheckAnimation;
end;

procedure TSkCustomAnimatedControl.SetFixedProgress(const AValue: Boolean);
begin
  if FFixedProgress <> AValue then
  begin
    FFixedProgress := AValue;
    CheckAnimation;
  end;
end;

procedure TSkCustomAnimatedControl.SetLoop(const AValue: Boolean);
begin
  if FLoop <> AValue then
  begin
    FLoop := AValue;
    CheckAnimation;
  end;
end;

procedure TSkCustomAnimatedControl.SetNewScene(AScene: IScene);
var
  LCanCheck: Boolean;
begin
  LCanCheck := Scene = nil;
  inherited;
  if LCanCheck then
    CheckAnimation;
end;

procedure TSkCustomAnimatedControl.SetProgress(AValue: Double);
begin
  FProgressChangedManually := True;
  AValue := EnsureRange(AValue, 0, 1);
  if not SameValue(FProgress, AValue, TEpsilon.Matrix) then
  begin
    FProgress := AValue;
    if SameValue(FProgress, 0, TEpsilon.Matrix) then
      FAnimationStartTickCount := TThread.GetTickCount;
    CheckAnimation;
    DoAnimationProgress;
    Repaint;
  end;
end;

{ TSkLottieAnimation }

function TSkLottieAnimation.CanRunAnimation: Boolean;
begin
  Result := Assigned(FSkottie) and inherited;
end;

procedure TSkLottieAnimation.DefineProperties(AFiler: TFiler);

  function DoWrite: Boolean;
  begin
    if AFiler.Ancestor <> nil then
      Result := (not (AFiler.Ancestor is TSkLottieAnimation)) or (TSkLottieAnimation(AFiler.Ancestor).Source <> FSource)
    else
      Result := FSource <> '';
  end;

begin
  inherited;
  AFiler.DefineBinaryProperty('TGS', ReadTgs, WriteTgs, DoWrite);
end;

procedure TSkLottieAnimation.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  if Assigned(FSkottie) then
    inherited
  else if csDesigning in ComponentState then
    DrawDesignBorder(ACanvas, ADest, AOpacity);
end;

function TSkLottieAnimation.GetDuration: Double;
begin
  if Assigned(FSkottie) then
    Result := FSkottie.Duration
  else
    Result := 0;
end;

procedure TSkLottieAnimation.LoadFromFile(const AFileName: string);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TSkLottieAnimation.LoadFromStream(const AStream: TStream);

  function IsTgs: Boolean;
  const
    GZipSignature: Word = $8B1F;
  var
    LSignature: Word;
    LSavePosition: Int64;
  begin
    if AStream.Size < 2 then
      Exit(False);
    LSavePosition := AStream.Position;
    try
      Result := (AStream.ReadData(LSignature) = SizeOf(Word)) and (LSignature = GZipSignature);
    finally
      AStream.Position := LSavePosition;
    end;
  end;

  function ReadStreamBuffer(const AStream: TStream): TBytes;
  begin
    SetLength(Result, AStream.Size - AStream.Position);
    if Length(Result) > 0 then
      AStream.ReadBuffer(Result, 0, Length(Result));
  end;

  function ReadTgsStreamBuffer(const AStream: TStream): TBytes;
  var
    LDecompressionStream: TDecompressionStream;
  begin
    LDecompressionStream := TDecompressionStream.Create(AStream, 31);
    try
      Result := ReadStreamBuffer(LDecompressionStream);
    finally
      LDecompressionStream.Free;
    end;
  end;

var
  LBuffer: TBytes;
begin
  if IsTgs then
    LBuffer := ReadTgsStreamBuffer(AStream)
  else
    LBuffer := ReadStreamBuffer(AStream);
  Source := TEncoding.UTF8.GetString(LBuffer);
end;

procedure TSkLottieAnimation.ReadTgs(AStream: TStream);
begin
  if AStream.Size = 0 then
    Source := ''
  else
    LoadFromStream(AStream);
end;

procedure TSkLottieAnimation.RenderFrame(const ACanvas: ISkCanvas;
  const ADest: TRectF; const AProgress: Double; const AOpacity: Single);
begin
  FSkottie.SeekFrameTime(AProgress * Duration);
  FSkottie.Render(ACanvas, ADest);
end;

procedure TSkLottieAnimation.SaveToFile(const AFileName: string);
const
  FormatExtension: array[TSkLottieFormat] of string = ('.json', '.tgs');
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    if AFileName.EndsWith(FormatExtension[TSkLottieFormat.Tgs], True) then
      SaveToStream(LStream, TSkLottieFormat.Tgs)
    else
      SaveToStream(LStream, TSkLottieFormat.Json);
  finally
    LStream.Free;
  end;
end;

procedure TSkLottieAnimation.SaveToStream(const AStream: TStream;
  const AFormat: TSkLottieFormat);

  function JsonToTgs(const ABytes: TBytes): TBytes;
  var
    LMemoryStream: TMemoryStream;
    LCompressStream: TCompressionStream;
  begin
    LMemoryStream := TMemoryStream.Create;
    try
      LCompressStream := TCompressionStream.Create(LMemoryStream, TZCompressionLevel.zcMax, 31);
      try
        LCompressStream.WriteBuffer(ABytes, Length(ABytes));
      finally
        LCompressStream.Free;
      end;
      SetLength(Result, LMemoryStream.Size);
      if LMemoryStream.Size > 0 then
        System.Move(LMemoryStream.Memory^, Result[0], LMemoryStream.Size);
    finally
      LMemoryStream.Free;
    end;
  end;

var
  LBuffer: TBytes;
begin
  LBuffer := TEncoding.UTF8.GetBytes(FSource);
  if AFormat = TSkLottieFormat.Tgs then
    LBuffer := JsonToTgs(LBuffer);
  if Length(LBuffer) > 0 then
    AStream.WriteBuffer(LBuffer, Length(LBuffer));
end;

procedure TSkLottieAnimation.SetSource(const AValue: TSkLottieSource);
begin
  if FSource <> string(AValue).Trim then
  begin
    FSource := string(AValue).Trim;
    if FSource = '' then
      FSkottie := nil
    else
      FSkottie := TSkottieAnimation.Make(FSource);
    if not FixedProgress then
      Progress := 0;
    CheckAnimation;
    Repaint;
  end;
end;

procedure TSkLottieAnimation.WriteTgs(AStream: TStream);
begin
  if FSource <> '' then
    SaveToStream(AStream, TSkLottieFormat.Tgs);
end;

initialization
  RegisterFMXClasses([TSkCustomControl, TSkLottieAnimation, TSkPaintBox, TSkSvgBrush, TSkSvg]);
end.
