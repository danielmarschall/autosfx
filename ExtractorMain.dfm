object MainForm: TMainForm
  Left = 222
  Top = 112
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'ViaThinkSoft AutoSFX Extractor'
  ClientHeight = 120
  ClientWidth = 359
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object WaitLabel: TLabel
    Left = 8
    Top = 8
    Width = 48
    Height = 13
    Caption = 'WaitLabel'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object CurrentFileLabel: TLabel
    Left = 8
    Top = 71
    Width = 233
    Height = 13
    AutoSize = False
    Caption = 'CurrentFileLabel'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object ProgressBar: TProgressBar
    Left = 8
    Top = 27
    Width = 341
    Height = 30
    Smooth = True
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 258
    Top = 87
    Width = 93
    Height = 25
    Cancel = True
    Caption = 'Abbrechen'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    TabStop = False
    OnClick = CancelBtnClick
  end
  object itemBar: TProgressBar
    Left = 8
    Top = 90
    Width = 233
    Height = 22
    Smooth = True
    TabOrder = 2
  end
  object AutoTimer: TTimer
    OnTimer = AutoTimerTimer
    Left = 320
    Top = 8
  end
end
