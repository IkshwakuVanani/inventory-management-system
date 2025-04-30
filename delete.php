<?php
require 'config.php';
$id = intval($_GET['id'] ?? 0);
if ($id) {
  $pdo->prepare("DELETE FROM items WHERE id=?")->execute([$id]);
}
header('Location:index.php');
exit;
