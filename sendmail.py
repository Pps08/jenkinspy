import sys
import win32com.client as win32
outlook=win32.Dispatch('outlook.application')
mail=outlook.CreateItem(0)
mail.To=sys.argv[1]
mail.Subject="QG mail"
mail.HTMLBody=sys.argv[2]
mail.Send()
print("Mail sent")
