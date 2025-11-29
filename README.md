###   🍽️ Cafetrack-App
A simple Flutter + Firebase based application to manage food items, inventory stock, and board games.  
Includes  real-time Firestore updates, search, details view, quantity control, and image support.

---
<p align="center">
  <img src="https://images2.imgbox.com/19/87/dnQbgMAe_o.png" width="350">
  <img src="https://thumbs2.imgbox.com/49/4a/mXsDakBm_t.png" width="350">
  <img src="https://thumbs2.imgbox.com/c5/27/m5LZVPR9_t.png" width="350">
  <img src="https://thumbs2.imgbox.com/bc/2c/Vb431dmy_t.png" width="350">
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





