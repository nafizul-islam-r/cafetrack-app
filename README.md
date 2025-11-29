###   🍽️ Cafetrack-App
A simple Flutter + Firebase based application to manage food items, inventory stock, and board games.  
Includes  real-time Firestore updates, search, details view, quantity control, and image support.

---
<p align="center">
  <img src="https://images2.imgbox.com/19/87/dnQbgMAe_o.png" width="350">
  <img src="https://images2.imgbox.com/f2/de/eQCMWO6q_o.png" width="350">
  <img src="https://images2.imgbox.com/55/74/9gObRdF6_o.png" width="350">
  <img src="https://images2.imgbox.com/ee/f5/32psT4GM_o.png" width="350">
</p>



## 🚀 Features
### 🥗 Food Item Management
- Add new food items (name, price, quantity, image URL)
- Edit existing food items
- Delete items
- Form validation
- Clean form UI
- Firestore integration (`food_items` collection)

### 📦 Inventory Management
- Real-time list of all inventory items
- Search by item name
- Quantity increase/decrease buttons
- Individual item details screen
- Live updates using Firestore streams

### 🎮 Board Game Management
- Add/Edit board games
- View board game details
- Manage availability/stock
- Real-time board game list
- Firestore connected (`board_games` collection)

---

## 🧱 Main Screens
### Food Items
- `AddFoodItemScreen`
- `FoodItemDetailsScreen`
- `InventoryListPage`

### Board Games
- `AddBoardGameScreen`
- `BoardGameDetailsScreen`
- `BoardGamesScreen`

---

## 🔥 Firebase Usage
The app uses the following Firestore collections:
- `food_items`
- `inventory`
- `board_games`





