<?php
require 'config.php';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $stmt = $pdo->prepare("INSERT INTO items (name,quantity,price) VALUES (?,?,?)");
  $stmt->execute([$_POST['name'], intval($_POST['quantity']), floatval($_POST['price'])]);
  header('Location:index.php'); exit;
}
?>
<!DOCTYPE html><html><body>
  <h2>Add Item</h2>
  <form method="post">
    <label>Name: <input name="name" required></label><br>
    <label>Qty: <input type="number" name="quantity" required></label><br>
    <label>Price: <input type="number" step="0.01" name="price" required></label><br>
    <button type="submit">Add</button>
  </form>
  <p><a href="index.php">← Back</a></p>
</body></html>
