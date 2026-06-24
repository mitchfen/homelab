from bs4 import BeautifulSoup
from requests import get as getHtml
from subprocess import check_output as runShellCommand

# Get current BIOS version
command = "sudo dmidecode -t 0 | grep Version"
stdout = runShellCommand(command, shell=True, text=True)
currentBiosVersion = stdout.split(":")[1].strip()

# Get latest BIOS version
url = "https://www.asrock.com/mb/AMD/B650E%20Steel%20Legend%20WiFi/BIOS.html"
response = getHtml(url)
response.raise_for_status()
soup = BeautifulSoup(response.content, "html.parser")

table = soup.find("table")
if not table:
    raise("No table found in the HTML.")

rows = table.find_all("tr")
if not rows:
    raise("No rows found in the table.")

cells = rows[1].find_all("td", recursive=False)
if not cells:
    raise("No cells found in the first row.")
else:
    latestBiosVersion = cells[0].text.strip()

updateText = "\033[32mNo need to update.\033[0m"
if currentBiosVersion < latestBiosVersion:
    updateText = "\033[33mYou should update!\033[0m"

print(f"Checked {url}")
print(f"Current BIOS: {currentBiosVersion}\nLatestBIOS: {latestBiosVersion}")
print(f"{updateText}")

