import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/__docusaurus/debug',
    component: ComponentCreator('/__docusaurus/debug', '5ff'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/config',
    component: ComponentCreator('/__docusaurus/debug/config', '5ba'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/content',
    component: ComponentCreator('/__docusaurus/debug/content', 'a2b'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/globalData',
    component: ComponentCreator('/__docusaurus/debug/globalData', 'c3c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/metadata',
    component: ComponentCreator('/__docusaurus/debug/metadata', '156'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/registry',
    component: ComponentCreator('/__docusaurus/debug/registry', '88c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/routes',
    component: ComponentCreator('/__docusaurus/debug/routes', '000'),
    exact: true
  },
  {
    path: '/',
    component: ComponentCreator('/', '351'),
    routes: [
      {
        path: '/',
        component: ComponentCreator('/', '8cc'),
        routes: [
          {
            path: '/',
            component: ComponentCreator('/', '02b'),
            routes: [
              {
                path: '/dao',
                component: ComponentCreator('/dao', 'f5b'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer',
                component: ComponentCreator('/developer', '732'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/examples',
                component: ComponentCreator('/developer/examples', '261'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/indexing',
                component: ComponentCreator('/developer/indexing', '5db'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/integration',
                component: ComponentCreator('/developer/integration', '992'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/sdk',
                component: ComponentCreator('/developer/sdk', '9d4'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/sdk/querying',
                component: ComponentCreator('/developer/sdk/querying', 'ae2'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/sdk/transactions',
                component: ComponentCreator('/developer/sdk/transactions', 'a4e'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/developer/subnames',
                component: ComponentCreator('/developer/subnames', '335'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry',
                component: ComponentCreator('/move-registry', 'f5f'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/design',
                component: ComponentCreator('/move-registry/design', '029'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/maintainer-practices',
                component: ComponentCreator('/move-registry/maintainer-practices', 'f95'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/managing-package-info',
                component: ComponentCreator('/move-registry/managing-package-info', '2c1'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/mvr-names',
                component: ComponentCreator('/move-registry/mvr-names', '5e0'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/tooling',
                component: ComponentCreator('/move-registry/tooling', '1a8'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/tooling/mvr-cli',
                component: ComponentCreator('/move-registry/tooling/mvr-cli', 'c60'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/move-registry/tooling/typescript-sdk',
                component: ComponentCreator('/move-registry/tooling/typescript-sdk', 'c1e'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/node-operator',
                component: ComponentCreator('/node-operator', 'a80'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/user',
                component: ComponentCreator('/user', 'c0d'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/user/avatar',
                component: ComponentCreator('/user/avatar', '27d'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/user/linked-address',
                component: ComponentCreator('/user/linked-address', '97a'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/user/registration',
                component: ComponentCreator('/user/registration', '975'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/user/renew',
                component: ComponentCreator('/user/renew', '630'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/user/sui-id',
                component: ComponentCreator('/user/sui-id', 'fae'),
                exact: true,
                sidebar: "suinsSidebar"
              },
              {
                path: '/',
                component: ComponentCreator('/', '109'),
                exact: true,
                sidebar: "suinsSidebar"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
