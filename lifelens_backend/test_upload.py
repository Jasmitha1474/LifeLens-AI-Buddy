import requests

url = 'http://192.168.0.108:8000/upload_file/'  # Replace with your actual IP
file_path = '/Users/apple/Desktop/OS/GenAIHack_4th AUg.pdf'
  # Replace with path to a real file on your computer

with open(file_path, 'rb') as f:
    files = {'file': (file_path, f)}
    response = requests.post(url, files=files)
    print(response.text)
