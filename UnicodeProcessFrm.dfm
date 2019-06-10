object Form34: TForm34
  Left = 0
  Top = 0
  Caption = 'Process UnicodeData.txt'
  ClientHeight = 306
  ClientWidth = 642
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    642
    306)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 39
    Width = 626
    Height = 259
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
    ExplicitWidth = 619
    ExplicitHeight = 252
  end
  object btnGO: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'GO'
    TabOrder = 1
    OnClick = btnGOClick
  end
  object btnTest: TButton
    Left = 96
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Test'
    TabOrder = 2
    OnClick = btnTestClick
  end
  object btnPerformanceTest: TButton
    Left = 184
    Top = 8
    Width = 113
    Height = 25
    Caption = 'PerformanceTest'
    TabOrder = 3
    OnClick = btnPerformanceTestClick
  end
  object btnTestCompareText: TButton
    Left = 303
    Top = 8
    Width = 114
    Height = 25
    Caption = 'Test CompareText'
    TabOrder = 4
    OnClick = btnTestCompareTextClick
  end
end
