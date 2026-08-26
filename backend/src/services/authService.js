const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const nodemailer = require('nodemailer');
const jwtService = require('./jwtService');
const { MyUser, EmailConfirmation } = require('../models');

// Create mail transporter
const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST,
  port: parseInt(process.env.MAIL_PORT || '587', 10),
  secure: false,
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
});

const authService = {
  /**
   * Pre-registration: check uniqueness, hash password.
   * Returns the user data object if OK, or an error string.
   */
  async preRegistrationProcess(userData) {
    // Check email
    const existingEmail = await MyUser.findOne({ where: { email: userData.email } });
    if (existingEmail) {
      return 'Email already exists';
    }
    // Check username
    if (userData.username) {
      const existingUsername = await MyUser.findOne({ where: { username: userData.username } });
      if (existingUsername) {
        return 'Username already exists';
      }
    }
    // Hash password
    const salt = await bcrypt.genSalt(10);
    userData.password = await bcrypt.hash(userData.password, salt);
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
    await EmailConfirmation.create({
      token: randomToken,
      createDate: new Date(),
      user_id: user.id,
    });

    const hostUrl = process.env.HOST_URL || 'http://localhost:8080/';
    const verificationLink = `${hostUrl}${path}${randomToken}`;

    const mailOptions = {
      from: process.env.MAIL_USER,
      to: user.email,
      subject: 'Email Verification for Localezy',
      text: `Email verification link: ${verificationLink}`,
    };

    // Send asynchronously (don't block)
    transporter.sendMail(mailOptions).catch((err) => {
      console.error('Failed to send email:', err);
    });

    return { message: `Email verification link sent to ${user.email}` };
  },

  /**
   * Verify email by token.
   */
  async verifyEmail(token) {
    const confirmation = await EmailConfirmation.findOne({
      where: { token },
      include: [{ association: 'myUser' }],
    });

    if (!confirmation) {
      return { error: 'Invalid token', status: 400 };
    }

    const user = confirmation.myUser;
    user.isEmailVerified = true;
    await user.save();

    return { message: 'Email verified successfully' };
  },

  /**
   * Authenticate user and return JWT token.
   */
  async authenticateAndGenerateToken(email, password) {
    const user = await MyUser.findOne({ where: { email } });
    if (!user) {
      return { error: 'Invalid credentials', status: 400 };
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return { error: 'Invalid credentials', status: 400 };
    }

    const token = jwtService.generateToken(user);
    return { token };
  },
};

module.exports = authService;
