import './style.css'

// Highlight active nav link
const links = document.querySelectorAll('.nav-links a')
const path = window.location.pathname.split('/').pop() || 'index.html'
links.forEach(l => {
  if (l.getAttribute('href') === path) l.classList.add('active')
})
