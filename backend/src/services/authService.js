const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const nodemailer = require('nodemailer');
const refreshTokenService = require('./refreshTokenService');
const { NearzyUser, EmailConfirmation } = require('../models');

// MAIL_USER doubles as the From address, so it stays set even for local
// catchers like Mailpit that accept mail without credentials. Offer AUTH only
// when a password exists — authenticating against a server that advertises no
// AUTH support fails the send outright.
const mailAuth = process.env.MAIL_PASS
  ? { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS }
  : undefined;

// Create mail transporter
const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.MAIL_PORT || '587', 10),
  secure: false,
  auth: mailAuth,
});

const authService = {
  /**
   * Pre-registration: check uniqueness, hash password.
   * Returns the user data object if OK, or an error string.
   */
  async preRegistrationProcess(userData) {
    // Check email
    const existingEmail = await NearzyUser.findOne({ where: { email: userData.email } });
    if (existingEmail) {
      return 'Email already exists';
    }
    // Check username
    if (userData.username) {
      const existingUsername = await NearzyUser.findOne({ where: { username: userData.username } });
      if (existingUsername) {
        return 'Username already exists';
      }
    }
    // Hash password
    const rawPassword = userData.password || userData.passwordHash;
    if (!rawPassword) {
      return 'Password is required';
    }
    const salt = await bcrypt.genSalt(10);
    userData.passwordHash = await bcrypt.hash(rawPassword, salt);
    delete userData.password;

    // Reset id if provided
    if (userData.id) {
      delete userData.id;
    }
    return userData;
  },

  /**
   * Send verification email.
   */
  async sendVerificationEmail(user, path) {
    const randomToken = uuidv4();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    await EmailConfirmation.create({
      token: randomToken,
      userId: user.id,
      expiresAt,
      used: false,
    });

    const hostUrl = process.env.HOST_URL || 'http://localhost:8080/';
    const verificationLink = `${hostUrl}${path}${randomToken}`;

    const mailOptions = {
      from: process.env.MAIL_USER,
      to: user.email,
      subject: 'Email Verification for Nearzy',
      text: `Email verification link: ${verificationLink}`,
    };

    // The account row is already committed, so a mail failure must not fail the
    // request — but it must not be reported as success either. Await the send so
    // the response reflects what actually happened.
    try {
      await transporter.sendMail(mailOptions);
      return { message: `Email verification link sent to ${user.email}`, emailSent: true };
    } catch (err) {
      console.error('Failed to send verification email:', err);
      return {
        message: `Account created, but the verification email to ${user.email} could not be sent.`,
        emailSent: false,
        // The SMTP error names hosts and credentials, so keep it out of production responses.
        ...(process.env.NODE_ENV === 'development' ? { emailError: err.message } : {}),
      };
    }
  },

  /**
   * Verify email by token.
   */
  async verifyEmail(token) {
    const confirmation = await EmailConfirmation.findOne({
      where: { token },
      include: [{ association: 'user' }],
    });

    if (!confirmation) {
      return { error: 'Invalid token', status: 400 };
    }

    if (confirmation.used) {
      return { error: 'Token already used', status: 400 };
    }

    if (confirmation.expiresAt && new Date(confirmation.expiresAt) < new Date()) {
      return { error: 'Token expired', status: 400 };
    }

    const user = confirmation.user;
    if (user) {
      user.isEmailVerified = true;
      await user.save();
    }

    confirmation.used = true;
    await confirmation.save();

    return { message: 'Email verified successfully' };
  },

  /**
   * Authenticate a user and open a session.
   *
   * Returns the whole session — access token, refresh token and the access
   * token's lifetime — rather than a bare JWT, so the client knows when to
   * refresh instead of waiting to be told by a 401.
   *
   * @param {string} email
   * @param {string} password
   * @param {{ deviceLabel?: string }} [meta]
   */
  async authenticateAndGenerateToken(email, password, meta = {}) {
    const user = await NearzyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'Invalid credentials', status: 400 };
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return { error: 'Invalid credentials', status: 400 };
    }

    const session = await refreshTokenService.issueSession(user, meta);
    // `token` is part of the session object, so callers that only ever wanted
    // the JWT keep working unchanged.
    return { ...session, session };
  },
};

module.exports = authService;
