import React from 'react';
import NavBar from './components/nav';
import Footer from './components/footer';

export default {
    logo: <span>Sui Name Service Docs</span>,
    project: {
      link: 'https://github.com/MystenLabs/suins-contracts'
    },
    feedback: {
      content: ""
    },
    editLink: {
      component: null
    },
    navbar: {
      component: NavBar,
    },
    footer: {
      component: Footer,
    }
    // ... other theme options
  }