<?php
// Quick cache purge - DELETE THIS FILE AFTER USE
$cache_dir = __DIR__ . '/cache/';
$count = 0;
if (is_dir($cache_dir)) {
    $files = glob($cache_dir . '*.php');
    foreach ($files as $file) {
        if (is_file($file)) {
            unlink($file);
            $count++;
        }
    }
    // Also clear twig cache
    $twig_dir = $cache_dir . 'twig/';
    if (is_dir($twig_dir)) {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($twig_dir, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::CHILD_FIRST
        );
        foreach ($iterator as $item) {
            if ($item->isFile()) { unlink($item->getRealPath()); $count++; }
            elseif ($item->isDir()) { rmdir($item->getRealPath()); }
        }
    }
}
echo "Cache purged. $count files deleted.";
