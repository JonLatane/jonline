
export function setDocumentTitle(title: string) {
  // console.log('setDocumentTitle', title)
  document.title = title;
  document.querySelector('meta[property="og:title"]')?.setAttribute('content', title);
}