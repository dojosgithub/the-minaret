const mongoose = require('mongoose');
const User = require('../models/User');
const Post = require('../models/Post');
const Notification = require('../models/Notification');
const bcrypt = require('bcryptjs');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI);

async function seedData() {
  try {
    // Clear existing data
    await User.deleteMany({});
    await Post.deleteMany({});
    await Notification.deleteMany({});

    // Create sample users with more detailed info
    const hashedPassword = await bcrypt.hash('test', 10);
    
    const users = await User.insertMany([
      {
        firstName: 'John',
        lastName: 'Doe',
        username: 'johndoe',
        email: 'test',
        password: hashedPassword,
        phoneNumber: '123456789',
        userType: 'Scholar',
        profileImage: '/uploads/profiles/default_profile.png',
        bio: 'Islamic Scholar specializing in Quranic studies and contemporary fiqh. Teaching and spreading knowledge for over 10 years.',
        followers: [], // Will be populated later
        following: [], // Will be populated later
        savedPosts: [], // Will be populated later
        recentSearches: [
          'Quranic studies',
          'Islamic history',
          'Fiqh rulings',
          'Hadith collection',
          'Islamic architecture'
        ],
      },
      {
        firstName: 'Jane',
        lastName: 'Smith',
        username: 'janesmith',
        email: 'test2',
        password: hashedPassword,
        phoneNumber: '1234567891',
        userType: 'Muslim',
        profileImage: '/uploads/profiles/default_profile.png',
        bio: 'Dedicated to learning and sharing Islamic knowledge. Interested in Islamic history and architecture.',
        followers: [], // Will be populated later
        following: [], // Will be populated later
        savedPosts: [], // Will be populated later
        recentSearches: [
          'Islamic architecture',
          'Mosque designs',
          'Islamic art',
          'Muslim community events',
          'Islamic education'
        ],
      },
    ]);

    // Create sample posts
    const posts = await Post.insertMany([
      {
        author: users[0]._id,
        type: 'Teaching Quran',
        title: 'Understanding Surah Al-Fatiha',
        body: 'The opening chapter of the Quran teaches us the most fundamental aspects of our faith...',
        media: [
          {
            type: 'image',
            url: 'https://picsum.photos/800/400'
          }
        ],
        links: [
          {
            title: 'Learn More About Surah Al-Fatiha',
            url: 'https://quran.com/1'
          }
        ],
        createdAt: new Date(),
      },
      {
        author: users[1]._id,
        type: 'Discussion',
        title: 'Importance of Prayer',
        body: 'Prayer is one of the five pillars of Islam. Here are some reflections on its significance...',
        media: [
          {
            type: 'image',
            url: 'https://picsum.photos/id/231/400/400'
          },
          {
            type: 'image',
            url: 'https://picsum.photos/id/232/400/400'
          }
        ],
        links: [
          {
            title: 'Prayer Times Calculator',
            url: 'https://www.islamicfinder.org'
          }
        ],
        createdAt: new Date(),
      },
      {
        author: users[0]._id,
        type: 'Hadith',
        title: 'Kindness in Islam',
        body: 'The Prophet (PBUH) said: "Kindness is a mark of faith, and whoever has no kindness has no faith."',
        media: [
          {
            type: 'image',
            url: 'https://picsum.photos/id/233/800/400'
          }
        ],
        links: [
          {
            title: 'Collection of Hadiths on Kindness',
            url: 'https://sunnah.com'
          }
        ],
        createdAt: new Date(),
      },
      {
        author: users[1]._id,
        type: 'Discussion',
        title: 'Islamic Architecture',
        body: 'Exploring the beauty of mosque architecture around the world...',
        media: [
          {
            type: 'image',
            url: 'https://picsum.photos/id/234/400/400'
          },
          {
            type: 'image',
            url: 'https://picsum.photos/id/235/400/400'
          },
          {
            type: 'image',
            url: 'https://picsum.photos/id/236/400/400'
          }
        ],
        links: [
          {
            title: 'Famous Mosques of the World',
            url: 'https://en.wikipedia.org/wiki/List_of_largest_mosques'
          }
        ],
        createdAt: new Date(),
      }
    ]);

    // Update users with followers and saved posts
    await User.findByIdAndUpdate(users[0]._id, {
      $push: {
        followers: users[1]._id,
        following: users[1]._id,
        savedPosts: [posts[1]._id, posts[3]._id]
      }
    });

    await User.findByIdAndUpdate(users[1]._id, {
      $push: {
        followers: users[0]._id,
        following: users[0]._id,
        savedPosts: [posts[0]._id, posts[2]._id]
      }
    });

    // Create sample notifications
    await Notification.insertMany([
      {
        recipient: users[1]._id,
        sender: users[0]._id,
        type: 'follow',
        message: 'Started following you',
        createdAt: new Date(),
      },
      {
        recipient: users[0]._id,
        sender: users[1]._id,
        type: 'like',
        message: 'Liked your post about Surah Al-Fatiha',
        createdAt: new Date(),
      },
    ]);

    console.log('Sample data inserted successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData(); 