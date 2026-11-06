export default defineNuxtConfig({
  compatibilityDate: '2026-11-06',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css'],
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      title: 'John Elrod - Leader in Software Engineering',
      meta: [
        { name: 'color-scheme', content: 'dark' },
        { name: 'theme-color', content: '#000000' },
      ],
    },
  },
})
