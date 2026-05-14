# 🏠 thd_house

A feature-rich housing system for the QBCore framework. This resource provides players with the ability to purchase, decorate, and manage their own homes across Los Santos, featuring a unique meta-key entry system and integrated storage solutions.

![Version](https://img.shields.io/badge/Version-1.0.0-green?style=for-the-badge)
![Living](https://img.shields.io/badge/Living-Premium-emerald?style=for-the-badge)

---

## ✨ Features

- **Meta-Key Access**: House entry is linked to physical key items with unique metadata, allowing for realistic key sharing.
- **Dynamic Property Purchase**: Real estate agents or automated systems can list any building as a purchasable home.
- **Custom Interiors**: Support for various shell-based and IPL-based interiors.
- **Integrated Stash**: Personal storage for every home to keep items safe.
- **Wardrobe System**: Access your saved outfits directly from your bedroom.
- **Knocking & Buzzing**: Interactive entry mechanics for guests.
- **Optimized Performance**: Highly efficient code with zero impact when players are outside of interiors.

---

## 🎨 Design Philosophy

`thd_house` is built for long-term player progression:
- **Emerald Highlights**: Interaction menus and confirmation buttons use AstraV green.
- **Glassmorphic UI**: Clean, premium interface for property management and menus.
- **Seamless Flow**: Smooth transitions when entering and exiting properties.

---

## 🛠️ Requirements

- **QBCore Framework**
- **ox_lib**
- **qb-target**
- **oxmysql**

---

## 🚀 Installation

1. Drag the `thd_house` folder into your `resources/[thd]` directory.
2. Add the following to your `server.cfg`:
   ```cfg
   ensure thd_house
   ```
3. Import the provided SQL file to initialize house listings and ownership tables.

---

## ⚙️ Configuration

Configure house prices and available interiors in `config.lua`:

```lua
Config = {}
Config.Interiors = {
    ["Apartment1"] = {
        label = "Standard Apartment",
        shell = "modern_apt_shell",
        price = 50000,
    }
}
```

---

## 🖱️ Interaction

- **Enter/Exit**: Use **Targeting (Alt)** on the front door. You must have the **House Key** in your inventory to unlock.
- **Management**: Access the house menu from inside the property to manage keys or sell the home.

---
