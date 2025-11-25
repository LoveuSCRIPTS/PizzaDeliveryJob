# PizzaDeliveryJob
FREE PizzaDeliveryJob for ESX!

# 🍕 Lovu Pizza Delivery
An advanced and optimized pizza delivery job for ESX Legacy, utilizing the modern ox_lib and ox_target interface.

# 📋 Features
Interactive NPC: Start and manage your shift via a realistic NPC interaction at the pizzeria.

Stock System: Drivers must manage their inventory (loading boxes onto the bike).

Delivery Timer: Players have a limited time to deliver each order.

Full Tuned Vehicles: Work vehicles spawn with max upgrades and full fuel.

Immersive Animations: Uses custom or default emotes for carrying pizza boxes.

# 🛠️ Requirements (Dependencies)
Before installing, ensure your server has the following resources:

es_extended (Legacy)

ox_lib

ox_target

# 📦 Installation
1. Upload Files
Place the lovu_pizzadelivery folder into your resources directory.

2. Server Config
Add the following line to your server.cfg (make sure it is below es_extended, ox_lib and ox_target):

Code snippet

ensure lovu_pizzadelivery
(Note: No SQL import is required for this script.)

⚙️ Configuration & Important Notes
🎭 Animation Setup (Emotes)
This script uses a command to trigger the box-carrying animation. By default, the script uses the command: /e carrypizza2

# ⚠️ IMPORTANT: If your server uses a different emote system (e.g., rpemotes, scully_emotes, or dpemotes) and you do not have the carrypizza2 animation, you must change this command.

Open the file: lovu_pizzadelivery/client/main.lua

Search (CTRL+F) for the text: ExecuteCommand

You will find lines like:

Lua

ExecuteCommand('e carrypizza2')
Change carrypizza2 to the name of the animation you use (e.g., box, pizza, etc.), or change the entire command if you use a different system.

# 🎮 How to Play
Start Shift: Go to the Pizzeria (Pizza Icon on map) and use Alt (Target) on the NPC. Select "Start Shift".

Get Stock: Open the menu again and select "Take New Stock".

Load Bike: Walk to your delivery scooter with the boxes and use Target to load them.

Deliver: Follow the GPS to the customer. Watch out for the timer!

Repeat: Once you run out of stock, return to the pizzeria to restock.
