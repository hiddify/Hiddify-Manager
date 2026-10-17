---
name: primevue
description: Setup and use PrimeVue UI component library in Vue/Vite projects with auto-import, theming, and component configuration. Use when working with PrimeVue components, setting up PrimeVue in a Vue project, configuring themes (Aura, Lara, etc.), or implementing auto-import for PrimeVue components.
---

# PrimeVue Setup and Usage

Guide for configuring PrimeVue with Vue 3 and Vite projects, including auto-import setup and theming.

## Overview

PrimeVue is a complete UI suite for Vue.js with rich components, icons, and templates. It supports both styled mode (pre-skinned themes like Aura, Lara, Nora) and unstyled mode (full styling control with Tailwind, Bootstrap, etc.).

## Documentation

Official LLM-optimized documentation: https://primevue.org/llms/pages/introduction.md

https://primevue.org/llms/llms.txt


## Installation

Install PrimeVue and themes:

```bash
npm install primevue @primeuix/themes
```

## Plugin Configuration

Configure PrimeVue plugin with theme in `main.ts`:

```typescript
import { createApp } from 'vue'
import PrimeVue from 'primevue/config'
import Aura from '@primeuix/themes/aura'
import App from './App.vue'

const app = createApp(App)
app.use(PrimeVue, {
  theme: {
    preset: Aura  // Available: Aura, Lara, Nora, etc.
  }
})
app.mount('#app')
```

## Auto Import Setup

Install auto-import dependencies:

```bash
npm install -D unplugin-vue-components @primevue/auto-import-resolver
```

Configure in `vite.config.ts`:

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import Components from 'unplugin-vue-components/vite'
import { PrimeVueResolver } from '@primevue/auto-import-resolver'

export default defineConfig({
  plugins: [
    vue(),
    Components({
      resolvers: [
        PrimeVueResolver()
      ]
    })
  ],
})
```

## Component Usage

With auto-import configured, use components directly without manual imports:

```vue
<template>
  <Button label="Click Me" />
  <InputText v-model="value" placeholder="Enter text" />
  <DataTable :value="items" />
</template>

<script setup lang="ts">
import { ref } from 'vue'
// No PrimeVue component imports needed - handled by auto-import

const value = ref('')
const items = ref([])
</script>
```

## Common Components

- **Button**: `<Button label="Text" />`
- **InputText**: `<InputText v-model="value" />`
- **Dropdown**: `<Dropdown v-model="selected" :options="items" />`
- **DataTable**: `<DataTable :value="data" />`
- **Dialog**: `<Dialog v-model:visible="show" />`
- **Card**: `<Card><template #title>Title</template></Card>`

## Theming

Available preset themes:
- `Aura` - Modern, clean design (recommended)
- `Lara` - Material-inspired
- `Nora` - Minimalist

Import and apply in plugin configuration as shown above.

## References

- Official docs: https://primevue.org
- Vite setup: https://primevue.org/llms/pages/vite.md
- Auto-import: https://primevue.org/llms/pages/autoimport.md
