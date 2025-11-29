###  Cafetrack-App
A simple Flutter + Firebase based application to manage food items, inventory stock, and board games.  
Includes  real-time Firestore updates, search, details view, quantity control, and image support.

---

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

Each document generally contains:
```json
{
  "name": "Item name",
  "price": 120.0,
  "quantity": 10,
  "imageUrl": "https://example.com/image.jpg"
}


