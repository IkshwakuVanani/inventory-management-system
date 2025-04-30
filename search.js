// auto-submit search form on input
document.getElementById('search').addEventListener('input', e => {
  e.target.form.submit();
});
