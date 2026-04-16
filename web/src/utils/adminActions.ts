export interface CsvColumn<T> {
  key: keyof T | string;
  header: string;
  accessor?: (item: T) => string | number;
}

export function downloadCsv<T>(filename: string, rows: T[], columns: CsvColumn<T>[]) {
  const escapeCell = (value: string | number) => {
    const normalized = String(value ?? '');
    return `"${normalized.replace(/"/g, '""')}"`;
  };

  const header = columns.map((column) => escapeCell(column.header)).join(',');
  const body = rows
    .map((row) =>
      columns
        .map((column) => {
          const value = column.accessor ? column.accessor(row) : (row[column.key as keyof T] as string | number);
          return escapeCell(value ?? '');
        })
        .join(',')
    )
    .join('\n');

  const csvContent = '\uFEFF' + [header, body].filter(Boolean).join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);

  link.href = url;
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

export function getPageNumbers(currentPage: number, totalPages: number) {
  if (totalPages <= 1) {
    return [1];
  }

  const pages = new Set<number>([1, totalPages, currentPage - 1, currentPage, currentPage + 1]);
  return Array.from(pages)
    .filter((page) => page >= 1 && page <= totalPages)
    .sort((first, second) => first - second);
}
