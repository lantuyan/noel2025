import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import { writeFileSync, mkdirSync, existsSync } from 'fs'
import { join, dirname, extname } from 'path'
import { fileURLToPath } from 'url'
import busboy from 'busboy'
import { v4 as uuidv4 } from 'uuid'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    {
      name: 'file-upload',
      configureServer(server) {
        server.middlewares.use('/api/upload', async (req, res, next) => {
          if (req.method !== 'POST') {
            return next()
          }

          try {
            const bb = busboy({ headers: req.headers })
            const uploadDir = join(__dirname, 'src', 'assets', 'images')
            
            // Ensure upload directory exists
            if (!existsSync(uploadDir)) {
              mkdirSync(uploadDir, { recursive: true })
            }

            let savedFilename: string | null = null
            let uploadError: Error | null = null

            bb.on('file', (name, file, info) => {
              const { filename, mimeType } = info
              
              // Validate file type
              if (!mimeType.startsWith('image/')) {
                file.resume()
                uploadError = new Error('File must be an image')
                return
              }

              // Generate unique filename
              const ext = extname(filename) || '.jpg'
              savedFilename = `${uuidv4()}${ext}`
              const filepath = join(uploadDir, savedFilename)

              // Save file
              const chunks: Buffer[] = []
              file.on('data', (chunk) => {
                chunks.push(chunk)
              })

              file.on('end', () => {
                try {
                  const buffer = Buffer.concat(chunks)
                  writeFileSync(filepath, buffer)
                } catch (err) {
                  uploadError = err instanceof Error ? err : new Error('Failed to save file')
                }
              })
            })

            bb.on('finish', () => {
              if (uploadError) {
                res.writeHead(400, { 'Content-Type': 'application/json' })
                res.end(JSON.stringify({ error: uploadError.message }))
              } else if (savedFilename) {
                res.writeHead(200, { 'Content-Type': 'application/json' })
                res.end(JSON.stringify({ 
                  success: true, 
                  filename: savedFilename 
                }))
              } else {
                res.writeHead(400, { 'Content-Type': 'application/json' })
                res.end(JSON.stringify({ error: 'No file uploaded' }))
              }
            })

            bb.on('error', (err) => {
              console.error('Upload error:', err)
              res.writeHead(500, { 'Content-Type': 'application/json' })
              res.end(JSON.stringify({ error: 'Upload failed' }))
            })

            req.pipe(bb)
          } catch (error) {
            console.error('Upload handler error:', error)
            res.writeHead(500, { 'Content-Type': 'application/json' })
            res.end(JSON.stringify({ error: 'Internal server error' }))
          }
        })
      }
    }
  ],
})
