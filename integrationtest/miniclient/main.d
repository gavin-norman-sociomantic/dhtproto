/*******************************************************************************

TODO

    Copyright:
        Copyright (c) 2018 dunnhumby Germany GmbH. All rights reserved.

    License:
        Boost Software License Version 1.0. See LICENSE.txt for details.

*******************************************************************************/

module integrationtest.miniclient.main;

import ocean.transition;

import turtle.runner.Runner;
import turtle.TestCase;

/// ditto
class TestRunner : TurtleRunnerTask!(TestedAppKind.Daemon)
{
    import turtle.env.Dht;

    override protected void configureTestedApplication ( out double delay,
        out istring[] args, out istring[istring] env )
    {
        delay = 0.1;
    }

    override public void prepare ( )
    {
        Dht.initialize();
        dht.start("127.0.0.1", 0);
        dht.genConfigFiles(this.context.paths.sandbox ~ "/etc");
    }

    override public void reset ( )
    {
        dht.clear();
    }
}

import dhtproto.util.MiniClient;

version ( UnitTest ) { }
else
int main ( istring[] args )
{
    auto runner = new TurtleRunner!(TestRunner)("dhtapp", "");
    return runner.main(args);
}

/*******************************************************************************

    Verifies scenario where test cases pushes records to a channel tested app
    listens on, both before and after fake node restart.

*******************************************************************************/

class GetPut : TestCase
{
    import turtle.env.Dht;

    import ocean.core.Test;
    import ocean.task.util.Timer;
    import Client = dhtproto.util.MiniClient;

    override void run ( )
    {
        Client.dht.connect(this.context.paths.sandbox ~ "/etc/dht.neo.nodes");
        Client.dht.getRaw("my_channel", 0);
    }
}
