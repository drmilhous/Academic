import requests
y = "??_Gexception@std@@UAEPAXI@Z"
yy="%3F%3F_Gexception%40std%40%40UAEPAXI%40Z%0A"
x = {"input":y}
r = requests.post("https://demangler.com/raw", data=x)
print(r.text)