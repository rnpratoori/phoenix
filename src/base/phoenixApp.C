#include "phoenixApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
phoenixApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

phoenixApp::phoenixApp(InputParameters parameters) : MooseApp(parameters)
{
  phoenixApp::registerAll(_factory, _action_factory, _syntax);
}

phoenixApp::~phoenixApp() {}

void
phoenixApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  ModulesApp::registerAllObjects<phoenixApp>(f, af, syntax);
  Registry::registerObjectsTo(f, {"phoenixApp"});
  Registry::registerActionsTo(af, {"phoenixApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
phoenixApp::registerApps()
{
  registerApp(phoenixApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
phoenixApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  phoenixApp::registerAll(f, af, s);
}
extern "C" void
phoenixApp__registerApps()
{
  phoenixApp::registerApps();
}
