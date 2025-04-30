<?php
require 'config.php';
$id = intval($_GET['id'] ?? 0);
if (!$id) exit('Invalid ID');
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $stmt = $pdo->prepare("UPDATE items SET name=?, quantity=?, price=? WHERE id=?");
  $stmt->execute([$_POST['name'], intval($_POST['quantity']), floatval($_POST['price']), $id]);
  header('Location:index.php'); exit;
}
$stmt = $pdo->prepare("SELECT * FROM items WHERE id=?");
$stmt->execute([$id]);
$item = $stmt->fetch();
?>
<!DOCTYPE html><html><body>
  <h2>Edit Item #<?= $id ?></h2>
  <form method="post">
    <label>Name: <input name="name" value="<?= htmlspecialchars($item['name']) ?>" required></label><br>
    <label>Qty: <input type="number" name="quantity" value="<?= $item['quantity'] ?>" required></label><br>
    <label>Price: <input type="number" step="0.01" name="price" value="<?= $item['price'] ?>" required></label><br>
    <button type="submit">Update</button>
  </form>
  <p><a href="index.php">← Back</a></p>
</body></html>
