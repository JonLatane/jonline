
export function setDocumentTitle(title: string) {
  document.title = title;
  document.querySelector('meta[property="og:title"]')?.setAttribute('content', title);
}