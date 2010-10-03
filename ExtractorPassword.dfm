object PasswordDlg: TPasswordDlg
  Left = 245
  Top = 108
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Daten-Entschl'#252'sselung'
  ClientHeight = 140
  ClientWidth = 290
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PwEnterLabel: TLabel
    Left = 8
    Top = 56
    Width = 117
    Height = 13
    Caption = 'Bitte Passwort eingeben.'
  end
  object FileLabel: TLabel
    Left = 8
    Top = 6
    Width = 28
    Height = 13
    Caption = 'Datei:'
  end
  object CurrentFileLabel: TLabel
    Left = 20
    Top = 25
    Width = 262
    Height = 13
    AutoSize = False
    Caption = 'CurrentFileLabel'
  end
  object TryLabel: TLabel
    Left = 241
    Top = 8
    Width = 41
    Height = 13
    Alignment = taRightJustify
    Caption = 'TryLabel'
  end
  object Password: TEdit
    Left = 8
    Top = 75
    Width = 274
    Height = 21
    PasswordChar = '*'
    TabOrder = 0
  end
  object OKBtn: TButton
    Left = 126
    Top = 102
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = OKBtnClick
  end
  object CancelBtn: TButton
    Left = 206
    Top = 102
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 2
  end
end
