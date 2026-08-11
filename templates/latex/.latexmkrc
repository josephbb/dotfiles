# latexmk defaults for this package
$pdf_mode = 1;
$bibtex_use = 2;
$biber = 'biber %O %S';

# Shared Zotero Better BibTeX export (optional cites in research statement / CV)
ensure_path( 'BIBINPUTS', "$ENV{HOME}/References" );

$preview_continuous_mode = 0;
