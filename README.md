# 🎨 SharedCanvas — Collaborative On-Chain Art on Flow EVM

**Deployed Contract:**  
[`0xDaEDfF5E06f3ca6bD86b75e4De07E484919b882A`](https://evm-testnet.flowscan.io/address/0xDaEDfF5E06f3ca6bD86b75e4De07E484919b882A)

---

## 🧩 Overview

**SharedCanvas** is a fully on-chain collaborative art experiment built for the **Flow EVM testnet**.  
It allows multiple users to co-create a shared digital canvas — one pixel at a time — using simple, no-input functions.  

No imports. No constructors. No user input fields.  
Just pure on-chain logic and community creativity.

---

## 🚀 Features

- 🖌️ **Collaborative Painting:** Everyone contributes pixels in sequence — one call per paint.
- 🎨 **Color Cycling:** Each user can cycle through a preset palette to choose colors.
- 🧱 **Pixel Claiming:** Reserve your spot before painting.
- 🕒 **Cooldown Protection:** Prevents spam painting.
- 🔒 **Finalization:** Admin can freeze the canvas when the masterpiece is complete.
- ⚙️ **No External Imports:** 100% self-contained Solidity contract.

---

## 🧠 Core Concept

Every call paints the **next unpainted pixel** in the grid.  
Your color is determined by your **personal color index**, which you can rotate using `cycleColor()`.

The result is a slowly evolving, collective artwork created entirely on-chain.

---

## ⚒️ Contract Functions

| Function | Description |
|-----------|--------------|
| `initialize()` | Admin initializes the canvas (16x16 grid, 10-color palette). |
| `paint()` | Paints the next available pixel using your selected color. |
| `cycleColor()` | Cycles your color index through the palette. |
| `claimPixel()` | Reserves the next pixel before painting. |
| `getCanvas()` | Returns full ownership and color data of the canvas. |
| `getMyPixels()` | Lists all pixels you’ve painted. |
| `mySelectedColor()` | Shows your current color index and name. |
| `canvasInfo()` | Displays canvas size, progress, and metadata. |
| `adminClearCanvas()` | Admin can reset all pixels. |
| `adminFinalize()` | Locks the canvas permanently. |

---

## 🔗 Deployment Info

- **Network:** Flow EVM Testnet  
- **Contract Address:** [`0xDaEDfF5E06f3ca6bD86b75e4De07E484919b882A`](https://evm-testnet.flowscan.io/address/0xDaEDfF5E06f3ca6bD86b75e4De07E484919b882A)
- **Language:** Solidity ^0.8.0  
- **Imports:** None  
- **Constructor:** None  
- **Input Fields:** None  

---

## 💡 Interaction Tips

You can interact using [Remix](https://remix.ethereum.org) or any EVM-compatible testnet wallet.

1. Connect to **Flow EVM Testnet**.  
2. Load the contract at the address above.  
3. As admin (deployer):
   - Call `initialize()` once.
4. As any user:
   - Use `cycleColor()` to pick a color.
   - Call `paint()` to contribute your pixel.
5. Watch the shared canvas evolve pixel by pixel!

---

## 🧱 Project Philosophy

> “Art doesn’t need permission — it needs participation.”

This project explores **collective creation**, **on-chain permanence**, and **decentralized coordination** — proving that even simple smart contracts can produce complex, emergent art.

---

## ⚖️ License

MIT License © 2025  
Created for experimentation on the Flow EVM Testnet.

---

## 🪶 Author

Built by **Daksh** — an engineering student exploring on-chain creativity, game design, and tokenized collaboration.  
