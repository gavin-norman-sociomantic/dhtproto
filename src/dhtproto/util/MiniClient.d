module dhtproto.util.MiniClient;

import ocean.transition;
import swarm.neo.authentication.HmacDef : Key;

public MiniClient dht ( )
{
    return dht("test", Key.init.content);
}

public MiniClient dht ( cstring auth_name, ubyte[] auth_key )
{
    if ( singleton_client is null )
        singleton_client = new MiniClient(auth_name, auth_key);
    return singleton_client;
}

private MiniClient singleton_client;

public class MiniClient
{
    import dhtproto.client.DhtClient;
    import ocean.core.Enforce;
    import ocean.task.Scheduler;
    import ocean.util.serialize.contiguous.Contiguous;
    import ocean.util.serialize.Version;
    import ocean.util.serialize.contiguous.Deserializer;
    import ocean.util.serialize.contiguous.MultiVersionDecorator;

    private DhtClient client;

    static private VersionDecorator version_decorator;

    public this ( )
    {
        this("test", Key.init.content);
    }

    public this ( cstring auth_name, ubyte[] auth_key )
    {
        if ( !isSchedulerUsed() )
            initScheduler(SchedulerConfiguration.init);

        this.client = new DhtClient(theScheduler.epoll);
    }

    public void connect ( cstring nodes_file_path )
    {
        this.client.neo.addNodes(nodes_file_path);
        this.client.blocking.waitAllNodesConnected();
    }

    public void[] getRaw ( cstring channel, hash_t key )
    {
        void[] value;
        auto r = this.client.blocking.get(channel, key, value);
        enforce(r.succeeded);
        return r.value;
    }

    public T* get ( T ) ( cstring channel, hash_t key )
    {
        void[] value;
        auto r = this.client.blocking.get(channel, key, value);
        enforce(r.succeeded);

        Contiguous!(T) deserialized;
        return this.deserialize!(T)(r.value, deserialized);
    }

    private T* deserialize ( T ) ( void[] src, ref Contiguous!(T) dst )
    {
        static if ( Version.Info!(T).exists )
        {
            if ( version_decorator is null )
                version_decorator = new VersionDecorator;

            return version_decorator.loadCopy!(T)(src, dst).ptr;
        }
        else
        {
            return Deserializer.deserialize(src, dst).ptr;
        }
    }
}

///
unittest
{
    void quickDhtUsage ( )
    {
        struct MyRecord
        {
            mstring name;
            hash_t category_id;
        }

        dht.connect("dht.nodes");
        dht.get!(MyRecord)("my_channel", 0);
    }
}
