# Docker Application - Nginx Web Server

This directory contains the containerized nginx web application with custom static content.

## 📁 Structure

```
docker/
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Local development environment
├── nginx.conf              # Custom nginx configuration
└── src/
    ├── index.html          # Home page with modern UI
    └── about.html          # About page with project details
```

## 🐳 Docker Configuration

### Dockerfile Features
- **Base Image**: nginx:alpine for minimal size and security
- **Custom Configuration**: Optimized nginx settings
- **Health Check**: Built-in health monitoring
- **Security**: Security headers and best practices
- **Static Content**: Custom HTML/CSS content

### Building the Image

```bash
# Build locally
docker build -t my-app:latest .

# Run locally
docker run -p 80:80 my-app:latest
```

### Docker Compose

For local development:

```bash
# Start the application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the application
docker-compose down
```

## 🌐 Nginx Configuration

### Key Features
- **Performance**: Optimized for high performance
- **Compression**: Gzip compression enabled
- **Security**: Security headers configured
- **Health Endpoint**: `/health` endpoint for monitoring
- **Error Pages**: Custom error page handling

### Health Check
The application includes a health check endpoint at `/health` that returns:
```
HTTP/1.1 200 OK
Content-Type: text/plain

healthy
```

## 🎨 Web Application

### Pages
1. **Home Page** (`/`): Modern landing page with features overview
2. **About Page** (`/about.html`): Technical details and architecture

### Features
- **Responsive Design**: Mobile-friendly layout
- **Modern UI**: Gradient backgrounds and glass morphism effects
- **Interactive Elements**: Hover effects and animations
- **Accessibility**: Semantic HTML and proper contrast

## 🔧 Customization

### Adding Content
1. Edit files in the `src/` directory
2. Rebuild the Docker image
3. Deploy to ECS

### Nginx Configuration
- Edit `nginx.conf` for server configuration
- Modify security headers, compression settings, etc.
- Test changes locally with docker-compose

## 🧪 Testing

### Local Testing
```bash
# Health check
curl http://localhost/health

# Load test
ab -n 100 -c 10 http://localhost/

# Check response headers
curl -I http://localhost/
```

### Production Testing
```bash
# Health check
curl http://your-alb-dns/health

# Performance test
curl -w "@curl-format.txt" -o /dev/null http://your-alb-dns/
```

## 🔒 Security

### Security Headers
- `X-Frame-Options`: Prevents clickjacking
- `X-XSS-Protection`: XSS protection
- `X-Content-Type-Options`: MIME type sniffing prevention
- `Referrer-Policy`: Referrer information control
- `Content-Security-Policy`: Content security policy

### Best Practices
- Non-root user (nginx user)
- Minimal base image (Alpine Linux)
- No sensitive data in container
- Read-only filesystem where possible

## 📊 Monitoring

### Logs
- **Access Logs**: `/var/log/nginx/access.log`
- **Error Logs**: `/var/log/nginx/error.log`
- **Container Logs**: `docker logs <container-id>`

### Metrics
- Request count and rate
- Response times
- Error rates
- Resource usage

## 🚀 Deployment

This application is designed to be deployed on:
- **AWS ECS**: Primary deployment target
- **Kubernetes**: Can be adapted for K8s
- **Docker Swarm**: Suitable for Docker Swarm
- **Local Development**: Docker Compose

## 🔄 Updates

To update the application:
1. Modify content in `src/` directory
2. Update nginx configuration if needed
3. Rebuild Docker image
4. Push to ECR
5. Update ECS service

## 📝 Notes

- The application serves static content only
- All configuration is done through nginx.conf
- Health checks are essential for load balancer integration
- Security headers are configured for production use
