# Argo CD Presentation

## Overview

This is an interactive presentation about GitOps with Argo CD built using [impress.js](https://github.com/impress/impress.js).

## How to Use

### Option 1: Open Directly in Browser

1. Simply open `index.html` in your web browser:

   ```bash
   # From this directory
   cd /home/hauke/tmp/argocd-workshop/presentation/argocd
   
   # Open in browser
   open index.html              # macOS
   xdg-open index.html          # Linux
   start index.html             # Windows
   ```

2. The presentation will open in your default browser.

> **Note:** If you see slides stacked vertically without transitions, the JavaScript may not be loading. Try Option 2 instead.

### Option 2: Serve with a Local Web Server (Recommended)

For the best experience and proper JavaScript loading:

**Using Python:**

```bash
# Make sure you're in the presentation/argocd directory
cd /home/hauke/tmp/argocd-workshop/presentation/argocd

# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

**Using Node.js:**

```bash
npx http-server -p 8000
```

**Using PHP:**

```bash
php -S localhost:8000
```

Then open: `http://localhost:8000`

> **Troubleshooting:** If you see "Address already in use", either:
>
> - Use a different port: `python3 -m http.server 8001`
> - Kill the existing server: `pkill -f "http.server 8000"`

## Navigation

### Keyboard Controls

- **Arrow Keys** or **Space** - Next slide
- **Shift + Arrow Keys** - Previous slide
- **Home** - First slide
- **End** - Last slide
- **P** - Pause/Resume
- **Escape** - Slide overview (if enabled)

### Mouse Controls

- Click anywhere on a slide to advance
- Use browser navigation buttons

## Additional Resources

- [impress.js Documentation](https://github.com/impress/impress.js)
- [impress.js Examples](https://github.com/impress/impress.js/wiki/Examples-and-demos)
- [Creating Presentations with impress.js](https://github.com/impress/impress.js/blob/master/DOCUMENTATION.md)

## License

This presentation is part of the Argo CD Workshop materials.
Feel free to use, modify, and distribute for educational purposes.

---

**Happy Presenting! 🚀**
