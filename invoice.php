<?php
require 'config.php';
require 'fpdf.php';

$items = $pdo->query("SELECT * FROM items")->fetchAll();
$pdf = new FPDF();
$pdf->AddPage();
$pdf->SetFont('Arial','B',16);
$pdf->Cell(0,10,'Inventory Invoice',0,1,'C');
$pdf->Ln(5);
$pdf->SetFont('Arial','',12);

$total = 0;
foreach ($items as $it) {
  $line = sprintf("%s — Qty:%d @ $%.2f", $it['name'], $it['quantity'], $it['price']);
  $pdf->Cell(0,8,$line,0,1);
  $total += $it['quantity'] * $it['price'];
}

$pdf->Ln(5);
$pdf->SetFont('Arial','B',12);
$pdf->Cell(0,8,'Total: $'.number_format($total,2),0,1);
$pdf->Output();
