See:  https://gist.github.com/peterc/91d9bc6397eb93e65897c1826f35e345


# How to set up a basic Sinatra + React webapp in 2025

Let's say you want to use Ruby for the backend of a basic webapp but React on the frontend. Here's how.

*(Note: All tested on January 13, 2025 with Ruby 3.3, Sinatra 4.1.1, and React 18.3. Configs may change over time.)*

First, create the app folder and set up Sinatra:

```bash
mkdir my-sinatra-react-app
cd my-sinatra-react-app

bundle init
echo "gem 'sinatra'" >> Gemfile
echo "gem 'puma'" >> Gemfile
bundle install
```

Then populate `app.rb` (this just handles CORS, serving up the eventual public files, and provides a basic /api/hello endpoint for testing from the React frontend):

```ruby
require 'sinatra'
require 'json'

before do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*' if settings.development?
end

set :public_folder, 'public'

# An example API route for basic testing purposes
get '/api/hello' do
  { message: 'Hello from Sinatra!' }.to_json
end

get '/' do
  content_type 'text/html'
  send_file File.join(settings.public_folder, 'index.html')
end
```

Next we can get the JavaScript part sorted:

```bash
npm create vite@latest client -- --template react
cd client

npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

Tailwind, Vite, and React need a bit of configuring at this point.

`client/tailwind.config.js` then needs to become:

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

`client/vite.config.js` needs tweaking to proxy through the Sinatra app during dev so React can reach the backend routes:

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:4567'  // Assuming Sinatra runs on 4567, as it usually does
    }
  },
  build: {
    outDir: '../public'
  }
})
```

`client/src/App.jsx` can then become (for basic testing purposes):

```jsx
import { useState } from 'react'

const App = () => {
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)

  const fetchMessage = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/hello')
      const data = await response.json()
      setMessage(data.message)
    } catch (error) {
      setMessage('Error fetching message')
      console.error('Error:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8 max-w-md mx-auto">
      <h1 className="text-3xl font-bold mb-4">Sinatra + React App</h1>
      
      <button 
        onClick={fetchMessage}
        disabled={loading}
        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded disabled:opacity-50"
      >
        {loading ? 'Loading...' : 'Fetch Message'}
      </button>
      
      {message && (
        <div className="mt-4 p-4 border rounded bg-gray-50">
          <p className="text-gray-800">{message}</p>
        </div>
      )}
    </div>
  )
}

export default App
```

To get Tailwind working, we need this in `client/src/index.css` (append or replace, as you wish):

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Finally, in one terminal run this to get the Sinatra backend running (needed in any case to serve up the backend route):

```bash
ruby app.rb
```

Then in dev, run this to use Vite to make the frontend easier to develop:

```bash
cd client
npm run dev
```

For deployment or to test using Sinatra alone:
```bash
cd client
npm run build
cd ..
ruby app.rb    # or package / containerize and deploy at this point
```

Tada!

