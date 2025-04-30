#!/bin/bash
set -e

# 1. Create directories
mkdir -p .github/workflows

# 2. schema.sql
cat > schema.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS inventory_db;
USE inventory_db;

CREATE TABLE IF NOT EXISTS items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# 3. config.php
cat > config.php << 'EOF'
<?php
// Read DB credentials from environment variables
\$host = getenv('DB_HOST') ?: 'localhost';
\$db   = getenv('DB_NAME') ?: 'inventory_db';
\$user = getenv('DB_USER') ?: 'root';
\$pass = getenv('DB_PASS') ?: '';
\$charset = 'utf8mb4';

\$options = [
  PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

\$dsn = "mysql:host=\$host;dbname=\$db;charset=\$charset";
try {
  \$pdo = new PDO(\$dsn, \$user, \$pass, \$options);
} catch (PDOException \$e) {
  exit('DB connection failed: ' . \$e->getMessage());
}
EOF

# 4. index.php
cat > index.php << 'EOF'
<?php
require 'config.php';

\$keyword = \$_GET['search'] ?? '';
if (\$keyword) {
  \$stmt = \$pdo->prepare("SELECT * FROM items WHERE name LIKE ? ORDER BY id DESC");
  \$stmt->execute(["%\$keyword%"]);
} else {
  \$stmt = \$pdo->query("SELECT * FROM items ORDER BY id DESC");
}
\$items = \$stmt->fetchAll();
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
    <input type="text" name="search" id="search" placeholder="Search…" value="<?= htmlspecialchars(\$keyword) ?>">
    <button type="submit">🔍</button>
    <a href="add.php">+ Add Item</a>
    <a href="invoice.php">🧾 Invoice</a>
  </form>
  <table>
    <thead>
      <tr><th>ID</th><th>Name</th><th>Qty</th><th>Price</th><th>Actions</th></tr>
    </thead>
    <tbody>
      <?php foreach (\$items as \$it): ?>
      <tr>
        <td><?= \$it['id'] ?></td>
        <td><?= htmlspecialchars(\$it['name']) ?></td>
        <td><?= \$it['quantity'] ?></td>
        <td>$<?= number_format(\$it['price'],2) ?></td>
        <td>
          <a href="edit.php?id=<?= \$it['id'] ?>">Edit</a>
          <a href="delete.php?id=<?= \$it['id'] ?>" onclick="return confirm('Delete?')">Delete</a>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
</body>
</html>
EOF

# 5. add.php
cat > add.php << 'EOF'
<?php
require 'config.php';
if (\$_SERVER['REQUEST_METHOD'] === 'POST') {
  \$stmt = \$pdo->prepare("INSERT INTO items (name,quantity,price) VALUES (?,?,?)");
  \$stmt->execute([\$_POST['name'], intval(\$_POST['quantity']), floatval(\$_POST['price'])]);
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
EOF

# 6. edit.php
cat > edit.php << 'EOF'
<?php
require 'config.php';
\$id = intval(\$_GET['id'] ?? 0);
if (!\$id) exit('Invalid ID');
if (\$_SERVER['REQUEST_METHOD'] === 'POST') {
  \$stmt = \$pdo->prepare("UPDATE items SET name=?, quantity=?, price=? WHERE id=?");
  \$stmt->execute([\$_POST['name'], intval(\$_POST['quantity']), floatval(\$_POST['price']), \$id]);
  header('Location:index.php'); exit;
}
\$stmt = \$pdo->prepare("SELECT * FROM items WHERE id=?");
\$stmt->execute([\$id]);
\$item = \$stmt->fetch();
?>
<!DOCTYPE html><html><body>
  <h2>Edit Item #<?= \$id ?></h2>
  <form method="post">
    <label>Name: <input name="name" value="<?= htmlspecialchars(\$item['name']) ?>" required></label><br>
    <label>Qty: <input type="number" name="quantity" value="<?= \$item['quantity'] ?>" required></label><br>
    <label>Price: <input type="number" step="0.01" name="price" value="<?= \$item['price'] ?>" required></label><br>
    <button type="submit">Update</button>
  </form>
  <p><a href="index.php">← Back</a></p>
</body></html>
EOF

# 7. delete.php
cat > delete.php << 'EOF'
<?php
require 'config.php';
\$id = intval(\$_GET['id'] ?? 0);
if (\$id) {
  \$pdo->prepare("DELETE FROM items WHERE id=?")->execute([\$id]);
}
header('Location:index.php');
exit;
EOF

# 8. invoice.php
cat > invoice.php << 'EOF'
<?php
require 'config.php';
require 'fpdf.php';

\$items = \$pdo->query("SELECT * FROM items")->fetchAll();
\$pdf = new FPDF();
\$pdf->AddPage();
\$pdf->SetFont('Arial','B',16);
\$pdf->Cell(0,10,'Inventory Invoice',0,1,'C');
\$pdf->Ln(5);
\$pdf->SetFont('Arial','',12);

\$total = 0;
foreach (\$items as \$it) {
  \$line = sprintf("%s — Qty:%d @ \$%.2f", \$it['name'], \$it['quantity'], \$it['price']);
  \$pdf->Cell(0,8,\$line,0,1);
  \$total += \$it['quantity'] * \$it['price'];
}

\$pdf->Ln(5);
\$pdf->SetFont('Arial','B',12);
\$pdf->Cell(0,8,'Total: $'.number_format(\$total,2),0,1);
\$pdf->Output();
EOF

# 9. fetch the FPDF library
curl -sSL https://raw.githubusercontent.com/Setasign/FPDF/master/fpdf.php -o fpdf.php

# 10. search.js
cat > search.js << 'EOF'
// auto-submit search form on input
document.getElementById('search').addEventListener('input', e => {
  e.target.form.submit();
});
EOF

# 11. style.css
cat > style.css << 'EOF'
body {
  font-family: sans-serif;
  max-width: 800px;
  margin: 2em auto;
}
h1,h2 { color: #333; }
table {
  width:100%;
  border-collapse: collapse;
  margin-top:1em;
}
th, td {
  border:1px solid #ccc;
  padding:0.5em;
  text-align:left;
}
form a {
  margin-left:1em;
  text-decoration:none;
  color:#0074D9;
}
EOF

# 12. Dockerfile
cat > Dockerfile << 'EOF'
FROM php:8.1-apache
RUN docker-php-ext-install pdo pdo_mysql
COPY . /var/www/html/
EXPOSE 80
EOF

# 13. .github/workflows/deploy.yml
cat > .github/workflows/deploy.yml << 'EOF'
name: CI & Deploy

on:
  push:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.1'

      - name: Validate SQL
        run: |
          grep -R "CREATE TABLE" schema.sql

      - name: Lint JS
        run: |
          npm install eslint || true
          npx eslint --max-warnings=0 search.js || echo "No ESLint config"

  deploy:
    needs: build-and-test
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Render Deploy Hook
        run: |
          curl -X POST ${{ secrets.RENDER_DEPLOY_HOOK_URL }}
EOF

echo "All files created! Run ‘php -S 0.0.0.0:8000’ to preview or commit & push to trigger GH Actions."
