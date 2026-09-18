# App icon, localized name, and mobile back behavior

## Changes

- Replace the existing launcher/splash source image with the uploaded Tawasul icon and make an great Animation splash screen from the icon, preserving all prior project work.
- Set the in-app name to “Tawasul School OS” in English and “نظام تواصل المدرسي” in Arabic.
- Add localized Android and iOS display-name resources so installed apps follow the phone language once platform files are generated.
- Keep normal mobile back navigation for opened pages and show an Arabic/English exit confirmation only at the portal home.
- Record the completed work and the remaining local icon-generation/build step in the roadmap.

## Technical details

- Use Flutter navigation interception at the signed-in portal root; nested pages continue to pop normally.
- Exit only after the user chooses Yes; No dismisses the dialog and leaves the user on the home page.
- Do not run Flutter, compile, or remove prior work.