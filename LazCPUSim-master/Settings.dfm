object Form3: TForm3
  Left = 168
  Top = 258
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 139
  ClientWidth = 168
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 103
    Height = 13
    Caption = 'Cpu run Step Interval:'
  end
  object Label2: TLabel
    Left = 8
    Top = 56
    Width = 61
    Height = 13
    Caption = 'Memory size:'
  end
  object SpinEdit1: TSpinEdit
    Left = 8
    Top = 24
    Width = 105
    Height = 22
    MaxValue = 100000
    MinValue = 10
    TabOrder = 0
    Value = 10
  end
  object SpinEdit2: TSpinEdit
    Left = 8
    Top = 72
    Width = 105
    Height = 22
    Increment = 16
    MaxValue = 65536
    MinValue = 16
    TabOrder = 1
    Value = 2048
  end
  object Button1: TButton
    Left = 88
    Top = 104
    Width = 75
    Height = 25
    Caption = 'O.K.'
    Default = True
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 8
    Top = 104
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = Button2Click
  end
end
