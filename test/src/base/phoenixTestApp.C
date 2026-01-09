//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "phoenixTestApp.h"
#include "phoenixApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
phoenixTestApp::validParams()
{
  InputParameters params = phoenixApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

phoenixTestApp::phoenixTestApp(InputParameters parameters) : MooseApp(parameters)
{
  phoenixTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

phoenixTestApp::~phoenixTestApp() {}

void
phoenixTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  phoenixApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"phoenixTestApp"});
    Registry::registerActionsTo(af, {"phoenixTestApp"});
  }
}

void
phoenixTestApp::registerApps()
{
  registerApp(phoenixApp);
  registerApp(phoenixTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
phoenixTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  phoenixTestApp::registerAll(f, af, s);
}
extern "C" void
phoenixTestApp__registerApps()
{
  phoenixTestApp::registerApps();
}
