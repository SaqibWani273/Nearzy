# Stage 1: Install dependencies
FROM node:18-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --only=production

# Stage 2: Production image
FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY . .

# Remove dev files from production image
RUN rm -rf .env .git .gitignore

EXPOSE 8080

ENV NODE_ENV=production
ENV PORT=8080

CMD ["node", "src/server.js"]
