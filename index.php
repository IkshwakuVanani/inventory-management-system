<?php
require 'config.php';

$keyword = $_GET['search'] ?? '';
if ($keyword) {
  $stmt = $pdo->prepare("SELECT * FROM items WHERE name LIKE ? ORDER BY id DESC");
  $stmt->execute(["%$keyword%"]);
} else {
  $stmt = $pdo->query("SELECT * FROM items ORDER BY id DESC");
}
$items = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Inventory System</title>
  <link rel="stylesheet" href="style.css">
  <script src="search.js" defer></script>
</head>
<body>
  <h1>Inventory</h1>
  <form method="get">
    <input type="text" name="search" id="search" placeholder="Search…" value="<?= htmlspecialchars($keyword) ?>">
    <button type="submit">🔍</button>
    <a href="add.php">+ Add Item</a>
    <a href="invoice.php">🧾 Invoice</a>
  </form>
  <table>
    <thead>
      <tr><th>ID</th><th>Name</th><th>Qty</th><th>Price</th><th>Actions</th></tr>
    </thead>
    <tbody>
      <?php foreach ($items as $it): ?>
      <tr>
        <td><?= $it['id'] ?></td>
        <td><?= htmlspecialchars($it['name']) ?></td>
        <td><?= $it['quantity'] ?></td>
        <td>$<?= number_format($it['price'],2) ?></td>
        <td>
          <a href="edit.php?id=<?= $it['id'] ?>">Edit</a>
          <a href="delete.php?id=<?= $it['id'] ?>" onclick="return confirm('Delete?')">Delete</a>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
</body>
</html>
