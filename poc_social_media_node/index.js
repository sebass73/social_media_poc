const express = require("express");
const session = require("express-session");
const passport = require("passport");
const GoogleStrategy = require("passport-google-oauth20").Strategy;
const FacebookStrategy = require("passport-facebook").Strategy;
const jwt = require("jsonwebtoken");

const app = express();

// Configurar sesión en Express
app.use(
  session({
    secret: "your_secret_key",
    resave: false,
    saveUninitialized: true,
  })
);

// Inicializar Passport y sesión
app.use(passport.initialize());
app.use(passport.session());

// Serialización y deserialización de usuarios
passport.serializeUser((user, done) => {
  done(null, user);
});

passport.deserializeUser((obj, done) => {
  done(null, obj);
});

// Estrategia de Google
passport.use(
  new GoogleStrategy(
    {
      clientID:
        "your_client_id",
      clientSecret: "your_client_secret",
      callbackURL:
        "https://2188-2800-2202-4000-272-596a-b1b8-ee1d-815d.ngrok-free.app/auth/google/callback",
    },
    (accessToken, refreshToken, profile, done) => {
      const userProfile = {
        displayName: profile.displayName,
        email: profile.emails[0].value,
      };

      done(null, userProfile);
    }
  )
);

// Estrategia de Facebook
passport.use(
  new FacebookStrategy(
    {
      clientID: "TU_CLIENT_ID_DE_FACEBOOK",
      clientSecret: "TU_CLIENT_SECRET_DE_FACEBOOK",
      callbackURL: "/auth/facebook/callback",
      profileFields: ["id", "emails", "name"],
    },
    (accessToken, refreshToken, profile, done) => {
      return done(null, profile);
    }
  )
);

// Rutas de autenticación
app.get(
  "/auth/google",
  passport.authenticate("google", { scope: ["profile", "email"] })
);

app.get(
  "/auth/google/callback",
  passport.authenticate("google", { failureRedirect: "/" }),
  (req, res) => {
    // Generar un JWT
    const token = jwt.sign({ user: req.user }, "your_jwt_secret", {
      expiresIn: "1h",
    });

    const { displayName, email } = req.user;
    res.redirect(
      `com.mypoc://callback?token=${token}&displayName=${encodeURIComponent(
        displayName
      )}&email=${encodeURIComponent(email)}`
    );
  }
);

function ensureAuthenticated(req, res, next) {
  let token = req.headers["authorization"];

  if (!token) {
    return res
      .status(401)
      .json({ message: "No token provided, please login." });
  }

  if (token.startsWith("Bearer ")) {
    token = token.slice(7, token.length); // Elimina el prefijo 'Bearer '
  }

  jwt.verify(token, "your_jwt_secret", (err, decoded) => {
    if (err) {
      return res
        .status(401)
        .json({ message: "Invalid token, please login again." });
    }
    req.user = decoded.user; // Extrae el usuario del token

    next();
  });
}

// Ruta protegida
app.get("/dashboard", ensureAuthenticated, (req, res) => {
  res.json({
    message: `¡Bienvenido, ${req.user.displayName}!`, // Enviar un mensaje en formato JSON
  });
});

app.get(
  "/auth/facebook",
  passport.authenticate("facebook", { scope: ["email"] })
);

app.get(
  "/auth/facebook/callback",
  passport.authenticate("facebook", { failureRedirect: "/" }),
  (req, res) => {
    // Generar un JWT o manejar la sesión
    const token = jwt.sign({ user: req.user }, "your_jwt_secret", {
      expiresIn: "1h",
    });
    res.json({ token });
  }
);

// Ruta para cerrar sesión
app.get("/logout", (req, res, next) => {
  // Eliminar la sesión del usuario
  req.logout((err) => {
    if (err) {
      return next(err);
    }
    // Destruir la sesión en el backend
    req.session.destroy((err) => {
      if (err) {
        return next(err);
      }
      // Redirigir o enviar una respuesta indicando que la sesión fue cerrada
      res.json({ message: "Sesión cerrada exitosamente." });
    });
  });
});

// Iniciar el servidor
app.listen(3000, () => {
  console.log("Servidor ejecutándose en http://localhost:3000");
});
